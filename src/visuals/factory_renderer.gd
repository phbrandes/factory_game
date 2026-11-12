class_name FactoryRenderer
extends Node2D

## Visual bridge. Listens to the simulation and spawns/manages visual nodes on an orthogonal grid.

const BeltVisualizerRef = preload("res://src/visuals/belt_visualizer.gd")
const MachineVisualizerRef = preload("res://src/visuals/machine_visualizer.gd")
const ExtractorVisualizerRef = preload("res://src/visuals/extractor_visualizer.gd")
const CombatVisualizerRef = preload("res://src/visuals/combat_visualizer.gd")
const VisualChunkManagerRef = preload("res://src/visuals/chunking/visual_chunk_manager.gd")

var simulation_grid: GridManager
var visual_map: Dictionary = {} # Maps GridEntity reference to its visual Node2D

# Optional mapping of entity_id strings to custom PackedScene templates.
var visual_registry: Dictionary = {}

# When true, entities not found in visual_registry automatically spawn the matching
# procedural visualizer (BeltVisualizer, MachineVisualizer, ExtractorVisualizer, CombatVisualizer)
# backed by VisualAssetRegistry textures.
var auto_create_visuals: bool = true

# Orthogonal grid cell size in pixels (default 64.0 = 4x scale of 16x16 pixel art tiles)
var cell_size_pixels: float = 64.0

# Optional VisualChunkManager for 16x16 spatial frustum culling (ADR-017).
# When null, visual nodes are added directly as children of FactoryRenderer.
var chunk_manager: VisualChunkManager = null

@onready var tile_map: TileMapLayer = get_node_or_null("TileMapLayer") as TileMapLayer

func _init() -> void:
	y_sort_enabled = true

func setup(p_grid: GridManager, p_chunk_manager: VisualChunkManager = null) -> void:
	simulation_grid = p_grid
	chunk_manager = p_chunk_manager
	simulation_grid.entity_placed.connect(_on_entity_placed)
	simulation_grid.entity_removed.connect(_on_entity_removed)

## Relays deterministic simulation ticks (ADR-015) to all active entity visualizers.
func on_simulation_tick() -> void:
	for visual_node in visual_map.values():
		if is_instance_valid(visual_node) and visual_node.has_method("on_simulation_tick"):
			visual_node.on_simulation_tick()

func _on_entity_placed(entity: GridEntity) -> void:
	var visual_node: Node2D = null
	
	# 1. Check custom PackedScene override in visual_registry first
	if visual_registry.has(entity.entity_id):
		var visual_scene: PackedScene = visual_registry[entity.entity_id]
		if visual_scene != null:
			visual_node = visual_scene.instantiate()
	elif auto_create_visuals:
		visual_node = _create_visualizer_for_entity(entity)
		
	if visual_node == null:
		return
		
	# 2. Add to scene tree (via VisualChunkManager if active, else directly)
	if chunk_manager != null:
		chunk_manager.add_visual_node(visual_node, entity.grid_position)
	else:
		add_child(visual_node)
		
	# 3. Apply Orthogonal Grid Math: Convert Vector2i grid to Vector2 pixel position
	if tile_map:
		visual_node.position = tile_map.map_to_local(entity.grid_position)
	else:
		visual_node.position = Vector2(entity.grid_position) * cell_size_pixels
		
	# 4. Store in tracking dictionary
	visual_map[entity] = visual_node

func _on_entity_removed(entity: GridEntity) -> void:
	if visual_map.has(entity):
		var visual_node = visual_map[entity]
		if is_instance_valid(visual_node):
			visual_node.queue_free()
		visual_map.erase(entity)

func _create_visualizer_for_entity(entity: GridEntity) -> Node2D:
	var id_lower := entity.entity_id.to_lower()
	
	# 1. Belt / Conveyor Segment
	if entity.get("items") != null and entity.get("length") != null:
		var belt_vis := BeltVisualizerRef.new()
		var dir := Vector2i(1, 0)
		if entity.get("facing_direction") != null:
			dir = entity.facing_direction
		belt_vis.setup_orthogonal(entity, dir, cell_size_pixels, _extract_tier(id_lower))
		return belt_vis
		
	# 2. Extractor / Robotic Arm
	if entity.get("source_pos") != null and entity.get("target_pos") != null:
		var ext_vis := ExtractorVisualizerRef.new()
		ext_vis.setup(entity, cell_size_pixels, _extract_tier(id_lower))
		return ext_vis
		
	# 3. Combat (Turrets, Walls, Enemies)
	if entity.get("targeting") != null or entity.get("speed_ticks") != null or id_lower.begins_with("turret") or id_lower.begins_with("defence") or id_lower.begins_with("orc") or id_lower.begins_with("slime"):
		var combat_vis := CombatVisualizerRef.new()
		combat_vis.setup(entity, cell_size_pixels)
		return combat_vis
		
	# 4. Machines, Miners, Furnaces, Assemblers, Splitters, Storage, Power, Labs
	var machine_vis := MachineVisualizerRef.new()
	machine_vis.setup(entity, cell_size_pixels)
	return machine_vis

func _extract_tier(id_lower: String) -> int:
	if id_lower.contains("4"): return 4
	if id_lower.contains("3"): return 3
	if id_lower.contains("2"): return 2
	return 1
