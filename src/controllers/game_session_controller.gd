class_name GameSessionController
extends Node2D

## Central Game Session & Deterministic Simulation Orchestrator (Milestone 2).
## Connects TickScheduler, WorldGenerator, GridManager, PowerNetwork, ProgressionManager,
## VisualChunkManager, WorldMapRenderer, and FactoryRenderer into a unified 10 TPS loop.

const GridManagerRef = preload("res://src/core/grid_manager.gd")
const GridEntityRef = preload("res://src/core/grid_entity.gd")
const BeltSegmentRef = preload("res://src/core/belt_segment.gd")
const MinerEntityRef = preload("res://src/core/miner_entity.gd")
const ProductionEntityRef = preload("res://src/core/production_entity.gd")
const ExtractorEntityRef = preload("res://src/core/extractor_entity.gd")
const SplitterEntityRef = preload("res://src/core/splitter_entity.gd")
const StorageEntityRef = preload("res://src/core/storage_entity.gd")
const TurretEntityRef = preload("res://src/core/combat/turret_entity.gd")
const EnemyEntityRef = preload("res://src/core/combat/enemy_entity.gd")
const PowerNetworkRef = preload("res://src/core/power_network.gd")
const PowerGeneratorComponentRef = preload("res://src/core/components/power_generator_component.gd")
const PowerConsumerComponentRef = preload("res://src/core/components/power_consumer_component.gd")
const ProgressionManagerRef = preload("res://src/core/progression/progression_manager.gd")
const ResearchEntityRef = preload("res://src/core/progression/research_entity.gd")
const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")
const TechResourceRef = preload("res://src/core/resources/tech_resource.gd")
const ReplaySystemRef = preload("res://src/core/replay_system.gd")
const TickSchedulerRef = preload("res://src/core/tick_scheduler.gd")
const WorldGeneratorRef = preload("res://src/core/world_generator.gd")

const WorldMapRendererRef = preload("res://src/visuals/world_map_renderer.gd")
const FactoryRendererRef = preload("res://src/visuals/factory_renderer.gd")
const VisualChunkManagerRef = preload("res://src/visuals/chunking/visual_chunk_manager.gd")

const CELL_SIZE: float = 64.0

@export var world_seed: int = 1337
@export var bootstrap_starter_factory: bool = true

var grid: GridManager
var world_generator: RefCounted
var power_network: PowerNetwork
var progression: ProgressionManager
var replay_system: RefCounted
var tick_scheduler: Node

var world_map_renderer: Node2D
var visual_chunk_manager: VisualChunkManager
var factory_renderer: FactoryRenderer
var active_camera: Camera2D

# Standard Recipe Catalog
var recipes: Dictionary = {}

# Ordered Simulation Lists for Deterministic 10 TPS Execution
var _production_entities: Array = []
var _logistics_entities: Array = []
var _research_entities: Array = []
var _turrets: Array = []
var _enemies: Array = []
var _generator_map: Dictionary = {} # GridEntity : PowerGeneratorComponent

func _ready() -> void:
	_init_recipes()
	
	replay_system = ReplaySystemRef.new(world_seed)
	grid = GridManagerRef.new()
	world_generator = WorldGeneratorRef.new(world_seed)
	power_network = PowerNetworkRef.new("main_grid")
	progression = ProgressionManagerRef.new()
	
	grid.entity_removed.connect(_on_entity_removed_from_grid)
	
	# 1. Ground & Resource Vein Renderer (Milestone 1)
	world_map_renderer = WorldMapRendererRef.new() as Node2D
	world_map_renderer.name = "WorldMapRenderer"
	add_child(world_map_renderer)
	world_map_renderer.setup(world_generator, CELL_SIZE)
	world_map_renderer.update_active_chunks(Vector2i(-1, -1), Vector2i(1, 1))
	
	# 2. Visual Chunk Manager + Factory Renderer (ADR-014 & ADR-017)
	visual_chunk_manager = VisualChunkManagerRef.new()
	visual_chunk_manager.name = "VisualChunkManager"
	
	factory_renderer = FactoryRendererRef.new()
	factory_renderer.name = "FactoryRenderer"
	factory_renderer.cell_size_pixels = CELL_SIZE
	add_child(factory_renderer)
	factory_renderer.add_child(visual_chunk_manager)
	factory_renderer.setup(grid, visual_chunk_manager)
	
	# 3. Default Camera (until PlayerController attaches its own Camera2D in Milestone 3)
	if active_camera == null:
		active_camera = Camera2D.new()
		active_camera.name = "SessionCamera"
		active_camera.position = Vector2(6, 4) * CELL_SIZE
		add_child(active_camera)
		
	# 4. Optional Starter Factory Bootstrap on the Starter Chunk (0, 0)
	if bootstrap_starter_factory:
		_spawn_starter_factory()
		
	# 5. Connect to TickScheduler Singleton
	tick_scheduler = get_node_or_null("/root/TickScheduler")
	if tick_scheduler == null:
		tick_scheduler = TickSchedulerRef.new()
		add_child(tick_scheduler)
	tick_scheduler.register_subscriber(_on_tick)
	tick_scheduler.start()

func _init_recipes() -> void:
	recipes["mine_iron"] = RecipeResourceRef.new("mine_iron", {}, {"iron_ore": 1}, 3)
	recipes["mine_copper"] = RecipeResourceRef.new("mine_copper", {}, {"copper_ore": 1}, 3)
	recipes["mine_coal"] = RecipeResourceRef.new("mine_coal", {}, {"coal": 1}, 3)
	recipes["mine_gold"] = RecipeResourceRef.new("mine_gold", {}, {"gold_ore": 1}, 4)
	recipes["smelt_iron"] = RecipeResourceRef.new("smelt_iron", {"iron_ore": 1}, {"iron_plate": 1}, 4)
	recipes["smelt_copper"] = RecipeResourceRef.new("smelt_copper", {"copper_ore": 1}, {"copper_plate": 1}, 4)
	recipes["smelt_steel"] = RecipeResourceRef.new("smelt_steel", {"iron_plate": 2}, {"steel": 1}, 6)
	recipes["craft_gear"] = RecipeResourceRef.new("craft_gear", {"iron_plate": 1}, {"iron_gear": 1}, 4)
	recipes["craft_wire"] = RecipeResourceRef.new("craft_wire", {"copper_plate": 1}, {"copper_cable": 2}, 3)
	recipes["craft_circuit"] = RecipeResourceRef.new("craft_circuit", {"iron_plate": 1, "copper_cable": 2}, {"circuit": 1}, 5)

## Instantiates the proper simulation entity class for entity_id, places it on the grid,
## registers it in the tick lists, and auto-links adjacent logistics.
func spawn_and_place_entity(entity_id: String, pos: Vector2i, facing: Vector2i = Vector2i.RIGHT) -> GridEntity:
	if not world_generator.is_tile_walkable(pos):
		return null
	if not grid.is_cell_empty(pos):
		return null
		
	var lower := entity_id.to_lower()
	var entity: GridEntity = null
	
	if lower.contains("miner"):
		var miner := MinerEntityRef.new(entity_id, 10)
		var ore_id: String = world_generator.get_resource_at(pos)
		if ore_id == "copper_ore":
			miner.set_mining_resource(recipes["mine_copper"])
		elif ore_id == "coal":
			miner.set_mining_resource(recipes["mine_coal"])
		elif ore_id == "gold_ore":
			miner.set_mining_resource(recipes["mine_gold"])
		else:
			miner.set_mining_resource(recipes["mine_iron"])
		entity = miner
		_production_entities.append(miner)
		
	elif lower.contains("furnace"):
		var furnace := ProductionEntityRef.new(entity_id, 10, 10)
		furnace.set_recipe(recipes["smelt_iron"])
		entity = furnace
		_production_entities.append(furnace)
		
	elif lower.contains("assembler"):
		var power_con: PowerConsumerComponent = null
		if lower.contains("2") or lower.contains("3") or lower.contains("4"):
			power_con = PowerConsumerComponentRef.new(10)
			power_network.register_consumer(power_con)
		var assembler := ProductionEntityRef.new(entity_id, 10, 10, Vector2i.ONE, power_con)
		assembler.set_recipe(recipes["craft_gear"])
		entity = assembler
		_production_entities.append(assembler)
		
	elif lower.contains("belt") or lower.contains("conveyor"):
		var belt := BeltSegmentRef.new(entity_id, 1, facing)
		entity = belt
		_logistics_entities.append(belt)
		
	elif lower.contains("extractor") or lower.contains("inserter") or lower.contains("arm"):
		var src := pos - facing
		var dst := pos + facing
		var arm := ExtractorEntityRef.new(entity_id, grid, src, dst, 2)
		entity = arm
		_logistics_entities.append(arm)
		
	elif lower.contains("splitter"):
		var splitter := SplitterEntityRef.new(entity_id)
		entity = splitter
		_logistics_entities.append(splitter)
		
	elif lower.contains("storage") or lower.contains("crate") or lower.contains("chest"):
		entity = StorageEntityRef.new(entity_id, 50)
		
	elif lower.contains("research") or lower.contains("lab"):
		var lab := ResearchEntityRef.new(entity_id, progression, 20)
		entity = lab
		_research_entities.append(lab)
		
	elif lower.contains("solar") or lower.contains("steam") or lower.contains("boiler"):
		entity = GridEntityRef.new(entity_id)
		var gen_rate := 50 if lower.contains("steam") else 20
		var gen := PowerGeneratorComponentRef.new(gen_rate)
		power_network.register_generator(gen)
		_generator_map[entity] = gen
		
	elif lower.contains("turret"):
		var turret := TurretEntityRef.new(entity_id, 6, 10)
		entity = turret
		_turrets.append(turret)
		
	elif lower in ["orc", "slime", "skeleton", "necromancer"]:
		var enemy := EnemyEntityRef.new(entity_id, 80, _get_current_tick(), 4)
		entity = enemy
		_enemies.append(enemy)
		
	else:
		entity = GridEntityRef.new(entity_id)
		
	if grid.place_entity(entity, pos):
		_relink_logistics_neighbors(pos)
		return entity
	return null

## Deterministic 10 TPS Simulation Step
func _on_tick(tick_number: int) -> void:
	# 1. Power Network Distribution
	power_network.tick()
	
	# 2. Mining & Production Machines
	for prod in _production_entities:
		if is_instance_valid(prod):
			_auto_select_furnace_recipe(prod)
			prod.tick()
			
	# 3. Logistics (Belts, Splitters, Extractors)
	for log_ent in _logistics_entities:
		if is_instance_valid(log_ent):
			log_ent.tick()
			
	# 4. Research Labs
	for lab in _research_entities:
		if is_instance_valid(lab):
			lab.tick()
			
	# 5. Combat (Enemies & Turrets)
	for turret in _turrets:
		if is_instance_valid(turret):
			turret.tick(_enemies)
			
	# 6. Visual Interpolation Sync (ADR-015)
	if factory_renderer != null:
		factory_renderer.on_simulation_tick()

func _process(_delta: float) -> void:
	if active_camera != null:
		var view_size := get_viewport_rect().size / active_camera.zoom
		var view_rect := Rect2(active_camera.global_position - view_size * 0.5, view_size)
		if world_map_renderer != null:
			world_map_renderer.update_from_world_rect(view_rect, 1)
		if visual_chunk_manager != null:
			var min_c := VisualChunkManagerRef.get_chunk_coord(Vector2i((view_rect.position / CELL_SIZE).floor())) - Vector2i.ONE
			var max_c := VisualChunkManagerRef.get_chunk_coord(Vector2i((view_rect.end / CELL_SIZE).ceil())) + Vector2i.ONE
			visual_chunk_manager.update_active_chunks(min_c, max_c)

## Automatically connects BeltSegments and SplitterEntities to adjacent downstream targets.
func _relink_logistics_neighbors(center_pos: Vector2i) -> void:
	var offsets := [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for off in offsets:
		var pos: Vector2i = center_pos + off
		var ent := grid.get_entity_at(pos)
		if ent is BeltSegment:
			var ahead_pos: Vector2i = ent.grid_position + ent.facing_direction
			ent.output_target = grid.get_entity_at(ahead_pos)
		elif ent is SplitterEntity:
			ent.outputs.clear()
			for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP]:
				var target := grid.get_entity_at(ent.grid_position + dir)
				if target != null and target != ent:
					ent.add_output(target)

func _auto_select_furnace_recipe(prod: Object) -> void:
	if prod == null or prod.get("entity_id") == null:
		return
	var id_str := String(prod.entity_id).to_lower()
	if not id_str.contains("furnace"):
		return
	var in_inv = prod.get("input_inventory")
	var crafter = prod.get("crafter")
	if in_inv == null or crafter == null:
		return
	if in_inv.contents.get("copper_ore", 0) > 0 and crafter.active_recipe != recipes["smelt_copper"]:
		prod.set_recipe(recipes["smelt_copper"])
	elif in_inv.contents.get("iron_ore", 0) > 0 and crafter.active_recipe != recipes["smelt_iron"]:
		prod.set_recipe(recipes["smelt_iron"])

func _on_entity_removed_from_grid(entity: GridEntity) -> void:
	_production_entities.erase(entity)
	_logistics_entities.erase(entity)
	_research_entities.erase(entity)
	_turrets.erase(entity)
	_enemies.erase(entity)
	if _generator_map.has(entity):
		power_network.generators.erase(_generator_map[entity])
		_generator_map.erase(entity)
	_relink_logistics_neighbors(entity.grid_position)

func _spawn_starter_factory() -> void:
	# Starter Iron line on Chunk (0, 0) iron deposit at (2, 2)
	spawn_and_place_entity("solar_panel", Vector2i(1, 1))
	spawn_and_place_entity("building_miner_t1", Vector2i(2, 2))
	spawn_and_place_entity("extractor_t1", Vector2i(3, 2), Vector2i.RIGHT)
	spawn_and_place_entity("belt_t1", Vector2i(4, 2), Vector2i.RIGHT)
	spawn_and_place_entity("belt_t1", Vector2i(5, 2), Vector2i.RIGHT)
	spawn_and_place_entity("extractor_t1", Vector2i(6, 2), Vector2i.RIGHT)
	spawn_and_place_entity("building_furnace_t1", Vector2i(7, 2))
	spawn_and_place_entity("extractor_t2", Vector2i(8, 2), Vector2i.RIGHT)
	spawn_and_place_entity("assembler_t2", Vector2i(9, 2))
	spawn_and_place_entity("extractor_t1", Vector2i(10, 2), Vector2i.RIGHT)
	spawn_and_place_entity("storage_t1", Vector2i(11, 2))

func _get_current_tick() -> int:
	if tick_scheduler != null and tick_scheduler.has_method("get_current_tick"):
		return int(tick_scheduler.get_current_tick())
	return 0
