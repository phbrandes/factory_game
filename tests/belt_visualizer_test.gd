extends Node

## Standalone test runner verifying time-based visual interpolation.

const BeltSegmentRef = preload("res://src/core/belt_segment.gd")
const BeltVisualizerRef = preload("res://src/visuals/belt_visualizer.gd")
const GridDirectionRef = preload("res://src/core/grid_direction.gd")

func run_tests() -> void:
	print("Running BeltVisualizer Tests...")
	
	_test_lerp_math()
	_test_state_caching()
	
	print("All BeltVisualizer tests passed.")

func _test_lerp_math() -> void:
	var belt_data = BeltSegmentRef.new("belt", 2)
	var visualizer = BeltVisualizerRef.new()
	
	# Setup facing EAST (Pixel vector: 64, 32)
	visualizer.setup(belt_data, GridDirectionRef.EAST)
	
	# Ensure pixel math maps correctly
	var pos_0 = visualizer._get_local_pixel_pos_for_index(0)
	var pos_1 = visualizer._get_local_pixel_pos_for_index(1)
	
	assert(pos_0 == Vector2.ZERO, "Index 0 should be local origin.")
	assert(pos_1 == Vector2(64, 32), "Index 1 should be offset by facing vector.")
	
	# Simulate an item moving from 0 to 1
	visualizer.previous_items = ["iron_ore", ""]
	visualizer.current_items = ["", "iron_ore"]
	
	# Force sprite creation
	visualizer._update_sprites()
	
	# Simulate 0.05s elapsed (Exactly 50% of the 0.1s tick)
	visualizer._process(0.05)
	
	var sprite: Sprite2D = visualizer.item_sprites[1]
	assert(sprite.visible == true, "Sprite should be visible for moving item.")
	
	# Lerping from (0,0) to (64, 32) at 50% should yield (32, 16)
	assert(sprite.position == Vector2(32, 16), "Lerp calculation failed or produced incorrect pixel coordinates.")

func _test_state_caching() -> void:
	var belt_data = BeltSegmentRef.new("belt", 2)
	var visualizer = BeltVisualizerRef.new()
	visualizer.setup(belt_data, GridDirectionRef.EAST)
	
	# Data Layer: Receive item
	belt_data.receive_item("copper_ore")
	
	# Visual Layer: Sync to tick
	visualizer.on_simulation_tick()
	
	assert(visualizer.previous_items == ["", ""], "Previous state not initialized correctly.")
	assert(visualizer.current_items == ["copper_ore", ""], "Failed to cache new state.")
	
	# Data Layer: Tick (Item shifts to index 1)
	belt_data.tick()
	
	# Visual Layer: Sync to next tick
	visualizer.on_simulation_tick()
	
	assert(visualizer.previous_items == ["copper_ore", ""], "Failed to cache previous state before update.")
	assert(visualizer.current_items == ["", "copper_ore"], "Failed to update current state.")