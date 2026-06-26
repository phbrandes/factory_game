class_name FactoryRenderer
extends Node2D

## Visual bridge. Listens to the simulation and spawns/manages visual nodes.

var simulation_grid: GridManager
var visual_map: Dictionary = {} # Maps GridEntity reference to its visual Node2D

# In a real setup, this is populated via the Inspector or a Resource database.
# For testing, we mock a mapping of entity_id strings to basic Sprite2D nodes.
var visual_registry: Dictionary = {} 

@onready var tile_map: TileMapLayer = get_node_or_null("TileMapLayer") as TileMapLayer

func setup(p_grid: GridManager) -> void:
	simulation_grid = p_grid
	simulation_grid.entity_placed.connect(_on_entity_placed)
	simulation_grid.entity_removed.connect(_on_entity_removed)

func _on_entity_placed(entity: GridEntity) -> void:
	# 1. Look up the visual template (PackedScene) for this entity ID
	if not visual_registry.has(entity.entity_id):
		return # No visual registered for this data object
		
	var visual_scene: PackedScene = visual_registry[entity.entity_id]
	var visual_node: Node2D = visual_scene.instantiate()
	
	# 2. Add to scene tree
	add_child(visual_node)
	
	# 3. Apply Isometric Math: Convert Vector2i grid to Vector2 pixel position
	if tile_map:
		visual_node.position = tile_map.map_to_local(entity.grid_position)
	else:
		# Fallback if TileMapLayer isn't ready (mostly for unit tests)
		visual_node.position = Vector2(entity.grid_position) * 64.0
		
	# 4. Store in tracking dictionary
	visual_map[entity] = visual_node

func _on_entity_removed(entity: GridEntity) -> void:
	if visual_map.has(entity):
		var visual_node = visual_map[entity]
		visual_node.queue_free()
		visual_map.erase(entity)