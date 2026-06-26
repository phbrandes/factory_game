extends Node

## Standalone test runner for the Decoupled Rendering Bridge.

const GridManagerRef = preload("res://src/core/grid_manager.gd")
const GridEntityRef = preload("res://src/core/grid_entity.gd")
const FactoryRendererRef = preload("res://src/visuals/factory_renderer.gd")

func run_tests() -> void:
	print("Running FactoryRenderer Tests...")
	
	_test_visual_spawning_and_cleanup()
	
	print("All FactoryRenderer tests passed.")

func _test_visual_spawning_and_cleanup() -> void:
	# 1. Setup Simulation
	var grid = GridManagerRef.new()
	
	# 2. Setup Renderer
	var renderer = FactoryRendererRef.new()
	add_child(renderer)
	
	# Create a dummy packed scene for testing (just a Node2D)
	var dummy_scene = PackedScene.new()
	var root_node = Node2D.new()
	dummy_scene.pack(root_node)
	root_node.free()
	
	renderer.visual_registry["assembler"] = dummy_scene
	renderer.setup(grid)
	
	# 3. Simulate Placement
	var entity = GridEntityRef.new("assembler")
	grid.place_entity(entity, Vector2i(5, 5))
	
	# Verify visual was created
	assert(renderer.visual_map.has(entity), "Renderer failed to track new entity.")
	var visual_node = renderer.visual_map[entity]
	assert(is_instance_valid(visual_node), "Visual node not properly instantiated.")
	assert(visual_node.get_parent() == renderer, "Visual node not added to scene tree.")
	
	# 4. Simulate Removal
	grid.remove_entity(entity)
	
	assert(not renderer.visual_map.has(entity), "Renderer failed to clear tracking map.")
	assert(visual_node.is_queued_for_deletion(), "Visual node was not queued for deletion.")