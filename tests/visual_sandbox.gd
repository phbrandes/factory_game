extends Node2D

## Interactive Visual Sandbox Scene
## Demonstrates all graphics elements from src/visuals/game_assets running live on an orthogonal grid:
## - Ground terrain & resource deposit patches
## - Live Miner -> Robotic Arm -> Conveyor Belt -> Stone Furnace -> Assembler -> Crate production line
## - Machine visual states (IDLE, WORKING, OUTPUT_FULL, NO_POWER)
## - Defense walls, Turrets, and animated Enemies (Orc, Slime, Skeleton, Necromancer) moving via FlowField
## - Interactive Camera2D pan/zoom and mouse placement ghost preview

const GridManagerRef = preload("res://src/core/grid_manager.gd")
const GridEntityRef = preload("res://src/core/grid_entity.gd")
const BeltSegmentRef = preload("res://src/core/belt_segment.gd")
const MinerEntityRef = preload("res://src/core/miner_entity.gd")
const ProductionEntityRef = preload("res://src/core/production_entity.gd")
const ExtractorEntityRef = preload("res://src/core/extractor_entity.gd")
const StorageEntityRef = preload("res://src/core/storage_entity.gd")
const SplitterEntityRef = preload("res://src/core/splitter_entity.gd")
const TurretEntityRef = preload("res://src/core/combat/turret_entity.gd")
const EnemyEntityRef = preload("res://src/core/combat/enemy_entity.gd")
const FlowFieldRef = preload("res://src/core/combat/flow_field.gd")
const PowerNetworkRef = preload("res://src/core/power_network.gd")
const PowerConsumerComponentRef = preload("res://src/core/components/power_consumer_component.gd")
const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")
const GridDirectionRef = preload("res://src/core/grid_direction.gd")

const TickSchedulerRef = preload("res://src/core/tick_scheduler.gd")
const WorldGeneratorRef = preload("res://src/core/world_generator.gd")
const WorldMapRendererRef = preload("res://src/visuals/world_map_renderer.gd")
const FactoryRendererRef = preload("res://src/visuals/factory_renderer.gd")
const VisualAssetRegistryRef = preload("res://src/visuals/visual_asset_registry.gd")

const CELL_SIZE: float = 64.0
const MAP_WIDTH: int = 18
const MAP_HEIGHT: int = 11

var grid: GridManager
var world_generator: RefCounted
var world_map_renderer: Node2D
var renderer: FactoryRenderer
var scheduler: Node
var camera: Camera2D
var ghost_sprite: Sprite2D
var hud_label: Label

var ticked_entities: Array = []
var enemies: Array = []
var turrets: Array = []
var flow_field: FlowField

var selected_build_id: String = "assembler_t1"
var build_palette: Array[String] = [
	"miner_t1",
	"furnace_t1",
	"assembler_t1",
	"assembler_t2",
	"splitter_t1",
	"storage_t1",
	"turret_gun_t1",
	"turret_laser_t1",
	"defence_wall_t1",
	"solar_panel",
	"steam_engine"
]
var palette_index: int = 0

func _ready() -> void:
	grid = GridManagerRef.new()
	world_generator = WorldGeneratorRef.new(1337)
	
	# 1. Procedural Chunked Ground & Resource Patch Layer (Milestone 1)
	world_map_renderer = WorldMapRendererRef.new() as Node2D
	world_map_renderer.name = "WorldMapRenderer"
	add_child(world_map_renderer)
	world_map_renderer.setup(world_generator, CELL_SIZE)
	world_map_renderer.update_active_chunks(Vector2i(-1, -1), Vector2i(1, 1))
	
	# 2. FactoryRenderer Bridge
	renderer = FactoryRendererRef.new()
	renderer.name = "FactoryRenderer"
	renderer.cell_size_pixels = CELL_SIZE
	add_child(renderer)
	renderer.setup(grid)
	
	# 3. Camera2D centered on the sandbox map
	camera = Camera2D.new()
	camera.position = Vector2(MAP_WIDTH * CELL_SIZE * 0.5, MAP_HEIGHT * CELL_SIZE * 0.5)
	add_child(camera)
	
	# 4. Build Ghost Preview Sprite
	ghost_sprite = Sprite2D.new()
	ghost_sprite.z_index = 20
	ghost_sprite.modulate = Color(0.2, 1.0, 0.2, 0.55)
	add_child(ghost_sprite)
	_update_ghost_texture()
	
	# 5. Populate Live Showcase Entities
	_setup_live_production_line()
	_setup_machine_states_row()
	_setup_combat_showcase_row()
	
	# 6. UI Overlay Instructions
	_setup_hud_overlay()
	
	# 7. Hook into TickScheduler singleton (or create local scheduler)
	scheduler = get_node_or_null("/root/TickScheduler")
	if scheduler == null:
		scheduler = TickSchedulerRef.new()
		add_child(scheduler)
	scheduler.register_subscriber(_on_simulation_tick)
	scheduler.start()

func _build_ground_and_resources() -> void:
	pass # Legacy helper removed, WorldMapRenderer handles terrain now

func _setup_live_production_line() -> void:
	# Row Y = 2: Miner -> Arm -> Belt (length 3) -> Arm -> Stone Furnace -> Arm -> Assembler -> Arm -> Crate
	var miner := MinerEntityRef.new("building_miner_t1", 10)
	var mine_iron := RecipeResourceRef.new("mine_iron", {}, {"iron_ore": 1}, 3)
	miner.set_mining_resource(mine_iron)
	grid.place_entity(miner, Vector2i(2, 2))
	ticked_entities.append(miner)
	
	var belt := BeltSegmentRef.new("belt_t1", 3)
	grid.place_entity(belt, Vector2i(4, 2))
	ticked_entities.append(belt)
	
	var arm_1 := ExtractorEntityRef.new("extractor_t1", grid, Vector2i(2, 2), Vector2i(4, 2), 2)
	grid.place_entity(arm_1, Vector2i(3, 2))
	ticked_entities.append(arm_1)
	
	var furnace := ProductionEntityRef.new("building_furnace_t1", 10, 10)
	var smelt_iron := RecipeResourceRef.new("smelt_iron", {"iron_ore": 1}, {"iron_plate": 1}, 4)
	furnace.set_recipe(smelt_iron)
	grid.place_entity(furnace, Vector2i(8, 2))
	ticked_entities.append(furnace)
	
	# Arm pulling from belt index 0 or furnace input: to keep belt moving continuously, feed belt directly & pull from furnace
	var arm_2 := ExtractorEntityRef.new("extractor_t2", grid, Vector2i(4, 2), Vector2i(8, 2), 2)
	grid.place_entity(arm_2, Vector2i(7, 2))
	ticked_entities.append(arm_2)
	
	var assembler := ProductionEntityRef.new("assembler_t1", 10, 10)
	var craft_gear := RecipeResourceRef.new("craft_gear", {"iron_plate": 1}, {"iron_gear": 1}, 4)
	assembler.set_recipe(craft_gear)
	grid.place_entity(assembler, Vector2i(10, 2))
	ticked_entities.append(assembler)
	
	var arm_3 := ExtractorEntityRef.new("extractor_t3", grid, Vector2i(8, 2), Vector2i(10, 2), 2)
	grid.place_entity(arm_3, Vector2i(9, 2))
	ticked_entities.append(arm_3)
	
	var crate := StorageEntityRef.new("storage_t2", 50)
	grid.place_entity(crate, Vector2i(12, 2))
	
	var arm_4 := ExtractorEntityRef.new("extractor_t1", grid, Vector2i(10, 2), Vector2i(12, 2), 2)
	grid.place_entity(arm_4, Vector2i(11, 2))
	ticked_entities.append(arm_4)
	
	# Second conveyor belt at (13, 2) pre-loaded with assorted items to show item icons gliding
	var showcase_belt := BeltSegmentRef.new("belt_t2", 4)
	showcase_belt.items = ["copper_ore", "iron_plate", "circuit", ""]
	grid.place_entity(showcase_belt, Vector2i(13, 2))
	ticked_entities.append(showcase_belt)

func _setup_machine_states_row() -> void:
	# Row Y = 5: Showcase Miner T2, Assembler T2 (WORKING), Assembler T3 (OUTPUT_FULL), Assembler T4 (NO_POWER), Boiler, Steam Engine, Solar Panel
	var miner_t2 := MinerEntityRef.new("miner_t2", 10)
	miner_t2.set_mining_resource(RecipeResourceRef.new("mine_copper", {}, {"copper_ore": 1}, 3))
	grid.place_entity(miner_t2, Vector2i(2, 5))
	ticked_entities.append(miner_t2)
	
	# Working Assembler T2
	var asm_working := ProductionEntityRef.new("assembler_t2", 20, 20)
	asm_working.set_recipe(RecipeResourceRef.new("infinite_circuits", {}, {"circuit": 1}, 5))
	grid.place_entity(asm_working, Vector2i(4, 5))
	ticked_entities.append(asm_working)
	
	# Output-Full Assembler T3 (amber tint)
	var asm_full := ProductionEntityRef.new("assembler_t3", 5, 2)
	asm_full.output_inventory.add_item("steel", 2)
	grid.place_entity(asm_full, Vector2i(6, 5))
	
	# Unpowered / Brownout Assembler T4 (dimmed + flashing lightning bolt icon)
	var power_comp := PowerConsumerComponentRef.new(100)
	var asm_nopower := ProductionEntityRef.new("assembler_t4", 5, 5, Vector2i.ONE, power_comp)
	grid.place_entity(asm_nopower, Vector2i(8, 5))
	
	# Splitter, Solar Panel, Boiler, Steam Engine, Electric Pole
	grid.place_entity(SplitterEntityRef.new("splitter_t2"), Vector2i(10, 5))
	grid.place_entity(GridEntityRef.new("solar_panel"), Vector2i(12, 5))
	grid.place_entity(GridEntityRef.new("boiler"), Vector2i(14, 5))
	grid.place_entity(GridEntityRef.new("steam_engine"), Vector2i(16, 5))

func _setup_combat_showcase_row() -> void:
	# Row Y = 8: Defense Walls, Turrets, and Enemies marching toward (4, 8)
	grid.place_entity(GridEntityRef.new("defence_wall_t1"), Vector2i(4, 7))
	grid.place_entity(GridEntityRef.new("defence_wall_t2"), Vector2i(4, 8))
	grid.place_entity(GridEntityRef.new("defence_wall_t3"), Vector2i(4, 9))
	
	var t1 := TurretEntityRef.new("turret_gun_t1", 6, 5)
	var t2 := TurretEntityRef.new("turret_laser_t1", 6, 8)
	var t3 := TurretEntityRef.new("turret_missile_t1", 7, 10)
	grid.place_entity(t1, Vector2i(3, 7))
	grid.place_entity(t2, Vector2i(3, 8))
	grid.place_entity(t3, Vector2i(3, 9))
	turrets.append_array([t1, t2, t3])
	
	var enemy_types := [
		{"id": "orc", "pos": Vector2i(10, 8), "hp": 120, "speed": 4},
		{"id": "slime", "pos": Vector2i(12, 7), "hp": 80, "speed": 3},
		{"id": "skeleton", "pos": Vector2i(13, 9), "hp": 100, "speed": 4},
		{"id": "necromancer", "pos": Vector2i(15, 8), "hp": 200, "speed": 5}
	]
	for info in enemy_types:
		var enemy_id: String = String(info["id"])
		var enemy_pos: Vector2i = info["pos"]
		var enemy_hp: int = int(info["hp"])
		var enemy_speed: int = int(info["speed"])
		var enemy := EnemyEntityRef.new(enemy_id, enemy_hp, 0, enemy_speed)
		grid.place_entity(enemy, enemy_pos)
		enemies.append(enemy)

func _on_simulation_tick(tick_num: int) -> void:
	# Keep the showcase belt looping its items so you can watch continuous 60 FPS belt movement
	for ent in ticked_entities:
		if ent is BeltSegmentRef and ent.entity_id == "belt_t2":
			var tail: String = ent.items[ent.length - 1]
			ent.tick()
			if tail != "":
				ent.receive_item(tail)
		else:
			ent.tick()
			
	# Step enemies & turrets
	for enemy in enemies:
		if enemy.health.current_health > 0:
			enemy._ticks_since_move += 1
			if enemy._ticks_since_move >= enemy.speed_ticks:
				enemy._ticks_since_move = 0
				enemy.grid_position += Vector2i(-1, 0)
				if enemy.grid_position.x <= 5:
					enemy.grid_position = Vector2i(15, enemy.grid_position.y)
		elif tick_num % 20 == 0:
			# Respawn defeated enemies in the sandbox so combat animation loops
			enemy.health.current_health = enemy.health.max_health
			enemy.grid_position = Vector2i(15, enemy.grid_position.y)
			
	for turret in turrets:
		turret.tick(enemies)
		
	renderer.on_simulation_tick()
	_update_hud_text(tick_num)

func _process(delta: float) -> void:
	# Camera panning with WASD / Arrow Keys
	var move_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_dir.x += 1
	camera.position += move_dir.normalized() * 400.0 * delta
	if move_dir != Vector2.ZERO and world_map_renderer != null:
		var view_size := get_viewport_rect().size / camera.zoom
		var view_rect := Rect2(camera.position - view_size * 0.5, view_size)
		world_map_renderer.update_from_world_rect(view_rect, 1)
	
	# Snap build ghost to mouse grid tile
	var mouse_world := get_global_mouse_position()
	var grid_pos := Vector2i(((mouse_world + Vector2.ONE * (CELL_SIZE * 0.5)) / CELL_SIZE).floor())
	ghost_sprite.global_position = Vector2(grid_pos) * CELL_SIZE
	if grid.is_area_empty(grid_pos, Vector2i.ONE):
		ghost_sprite.modulate = Color(0.2, 1.0, 0.2, 0.55)
	else:
		ghost_sprite.modulate = Color(1.0, 0.2, 0.2, 0.55)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_world := get_global_mouse_position()
		var grid_pos := Vector2i(((mouse_world + Vector2.ONE * (CELL_SIZE * 0.5)) / CELL_SIZE).floor())
		if event.button_index == MOUSE_BUTTON_LEFT:
			if grid.is_area_empty(grid_pos, Vector2i.ONE):
				var new_ent := GridEntityRef.new(selected_build_id)
				grid.place_entity(new_ent, grid_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var existing := grid.get_entity_at(grid_pos)
			if existing != null:
				grid.remove_entity(existing)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.1).clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom * 0.9).clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))
			
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB or event.keycode == KEY_E:
			palette_index = (palette_index + 1) % build_palette.size()
			selected_build_id = build_palette[palette_index]
			_update_ghost_texture()
		elif event.keycode == KEY_Q:
			palette_index = posmod(palette_index - 1, build_palette.size())
			selected_build_id = build_palette[palette_index]
			_update_ghost_texture()
		elif event.keycode == KEY_SPACE and scheduler != null:
			if scheduler.is_running():
				scheduler.pause()
			else:
				scheduler.resume()

func _update_ghost_texture() -> void:
	if ghost_sprite == null:
		return
	ghost_sprite.texture = VisualAssetRegistryRef.get_entity_preview_texture(selected_build_id)
	var scale_factor := CELL_SIZE / float(VisualAssetRegistryRef.NATIVE_TILE_PIXELS)
	ghost_sprite.scale = Vector2.ONE * scale_factor

func _setup_hud_overlay() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	canvas.add_child(panel)
	
	hud_label = Label.new()
	panel.add_child(hud_label)
	_update_hud_text(0)

func _update_hud_text(tick_num: int) -> void:
	if hud_label == null:
		return
	hud_label.text = (
		"FACTORY VISUAL SANDBOX (Tick: %d)\n" % tick_num +
		"• Row 1 (Top): Miner -> Robotic Arm -> Belt -> Furnace -> Assembler -> Crate + Belt Item Icons\n" +
		"• Row 2 (Mid): Miner T2 | Working Assembler | Full-Output (Amber) | No-Power (Lightning Icon) | Power Buildings\n" +
		"• Row 3 (Bot): Defense Walls & Turrets vs Animated Orc, Slime, Skeleton & Necromancer\n" +
		"Controls: [WASD/Arrows] Pan | [Wheel] Zoom | [Q/E or Tab] Cycle Building (%s) | [L-Click] Place | [R-Click] Remove | [Space] Pause" % selected_build_id
	)
