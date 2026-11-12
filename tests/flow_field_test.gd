extends Node

const GridManagerRef = preload("res://src/core/grid_manager.gd")
const FlowFieldRef = preload("res://src/core/combat/flow_field.gd")

func run_tests() -> void:
	print("  [DEBUG] Starting FlowField test...")
	
	# Step 1: Initialization
	print("  [DEBUG] Instantiating GridManager...")
	var grid = GridManagerRef.new()
	var core_pos = Vector2i(0, 0)
	
	print("  [DEBUG] Instantiating FlowField...")
	var field = FlowFieldRef.new(grid, core_pos)
	
	# Step 2: Propagation Test
	print("  [DEBUG] Running propagation checks...")
	
	# Check 1
	var dir1 = field.get_direction(Vector2i(1, 0))
	if dir1 != Vector2i(-1, 0):
		push_error("FAIL: Direction at (1,0) was %s, expected (-1,0)" % str(dir1))
	else:
		print("  [DEBUG] Check 1 passed.")
		
	# Check 2
	var dir2 = field.get_direction(Vector2i(1, 1))
	if dir2 != Vector2i(-1, 0) and dir2 != Vector2i(0, -1):
		push_error("FAIL: Direction at (1,1) was %s, expected (-1,0) or (0,-1)" % str(dir2))
	else:
		print("  [DEBUG] Check 2 passed.")

	print("  [DEBUG] FlowField tests completed.")