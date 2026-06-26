extends Node

const GridManagerRef = preload("res://src/core/grid_manager.gd")
const FlowFieldRef = preload("res://src/core/combat/flow_field.gd")

func run_tests() -> void:
	print("Running FlowField Tests...")
	_test_propagation()
	print("All FlowField tests passed.")

func _test_propagation() -> void:
	var grid = GridManagerRef.new()
	var core_pos = Vector2i(0, 0)
	
	# Create a simple 3x3 path
	var field = FlowFieldRef.new(grid, core_pos)
	
	# Tile at (1,0) should point toward (0,0) [Vector2i(-1, 0)]
	assert(field.get_direction(Vector2i(1, 0)) == Vector2i(-1, 0), "Incorrect direction vector.")
	
	# Tile at (1,1) should point toward (0,1) or (1,0)
	var dir = field.get_direction(Vector2i(1, 1))
	assert(dir == Vector2i(-1, 0) or dir == Vector2i(0, -1), "Flow field didn't route to core.")