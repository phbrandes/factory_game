extends Node

## Standalone test runner for Player Input and Radial Menu math.

const RadialMenuRef = preload("res://src/ui/radial_menu.gd")
const GridManagerRef = preload("res://src/core/grid_manager.gd")
const ReplaySystemRef = preload("res://src/core/replay_system.gd")
const PlayerInteractionControllerRef = preload("res://src/controllers/player_interaction_controller.gd")

func run_tests() -> void:
	print("Running PlayerInteraction Tests...")
	
	_test_radial_menu_math()
	_test_build_mode_toggle()
	
	print("All PlayerInteraction tests passed.")

func _test_radial_menu_math() -> void:
	var menu = RadialMenuRef.new()
	add_child(menu)
	
	menu.radius = 100.0
	var screen_center = Vector2(500, 500)
	menu.open(screen_center, ["Item1", "Item2", "Item3", "Item4"])
	
	assert(menu.is_open == true, "Menu failed to open.")
	assert(menu._active_buttons.size() == 4, "Menu failed to generate correct number of buttons.")
	
	# 4 items means angles: 0, 90, 180, 270 degrees.
	# Button 0 (0 degrees) should be at offset (100, 0) from center
	var btn_0 = menu._active_buttons[0]
	var expected_pos_0 = Vector2(100, 0) - (menu.button_size / 2.0)
	
	# We use is_equal_approx for float math precision differences
	assert(btn_0.position.is_equal_approx(expected_pos_0), "Button 0 math calculation incorrect.")
	
	menu.close()
	assert(menu.is_open == false, "Menu failed to close.")
	assert(menu._active_buttons.size() == 0, "Menu failed to clean up buttons.")

func _test_build_mode_toggle() -> void:
	var grid = GridManagerRef.new()
	var replay = ReplaySystemRef.new()
	# Dummy scheduler to satisfy dependency
	var dummy_scheduler = Node.new() 
	
	var menu = RadialMenuRef.new()
	var controller = PlayerInteractionControllerRef.new()
	
	# Setup controller (passing null for tile_map as we are testing headless logic)
	controller.call("setup", grid, replay, dummy_scheduler, null, menu)
	
	assert(controller.get("current_build_item_id") == "", "Should not start in build mode.")
	
	# Simulate selecting an item from the menu
	controller.call("_on_build_item_selected", "belt_t1")
	assert(controller.get("current_build_item_id") == "belt_t1", "Failed to enter build mode.")
	
	# Simulate right click (Cancel)
	var cancel_event = InputEventAction.new()
	cancel_event.action = "ui_cancel"
	cancel_event.pressed = true
	controller.call("_unhandled_input", cancel_event)
	
	assert(controller.get("current_build_item_id") == "", "Failed to exit build mode via cancel action.")