extends Node

## Standalone test runner for automatic conveyor connection logic.

const GridEntityRef = preload("res://src/core/grid_entity.gd")
const BeltSegmentRef = preload("res://src/core/belt_segment.gd")

var _grid: GridManager
var _router: LogisticsRouter

func run_tests() -> void:
	print("Running LogisticsRouter Tests...")
	_grid = load("res://src/core/grid_manager.gd").new()
	_router = load("res://src/core/logistics_router.gd").new(_grid)
	
	_test_linear_connection()
	_test_incoming_connection()
	_test_head_to_head_rejection()
	
	print("All LogisticsRouter tests passed.")

func _test_linear_connection() -> void:
	_grid.clear_all()
	# Belt A faces East, placed at (0, 0)
	var belt_a = BeltSegmentRef.new("belt", 1, GridDirection.EAST)
	_grid.place_entity(belt_a, Vector2i(0, 0))
	_router.route_entity(belt_a)
	
	assert(belt_a.output_target == null, "Belt A should have no target initially.")
	
	# Belt B faces East, placed at (1, 0), directly in front of A
	var belt_b = BeltSegmentRef.new("belt", 1, GridDirection.EAST)
	_grid.place_entity(belt_b, Vector2i(1, 0))
	
	# Routing B should trigger B looking forward (null), and A linking to B.
	_router.route_entity(belt_b)
	
	assert(belt_b.output_target == null, "Belt B should have no forward target.")
	assert(belt_a.output_target == belt_b, "Belt A failed to auto-link to Belt B.")

func _test_incoming_connection() -> void:
	_grid.clear_all()
	# Belt A faces North, placed at (5, 5). Output points to (5, 4)
	var belt_a = BeltSegmentRef.new("belt", 1, GridDirection.NORTH)
	_grid.place_entity(belt_a, Vector2i(5, 5))
	_router.route_entity(belt_a)
	
	assert(belt_a.output_target == null, "Belt A should be isolated.")
	
	# We place a machine (or belt) at (5, 4) AFTER Belt A was placed.
	var belt_b = BeltSegmentRef.new("belt", 1, GridDirection.EAST)
	_grid.place_entity(belt_b, Vector2i(5, 4))
	_router.route_entity(belt_b)
	
	# Belt A should have automatically updated its output to point to B.
	assert(belt_a.output_target == belt_b, "Incoming routing failed to update previously placed belts.")

func _test_head_to_head_rejection() -> void:
	_grid.clear_all()
	var belt_east = BeltSegmentRef.new("belt", 1, GridDirection.EAST)
	var belt_west = BeltSegmentRef.new("belt", 1, GridDirection.WEST)
	
	_grid.place_entity(belt_east, Vector2i(0, 0))
	_grid.place_entity(belt_west, Vector2i(1, 0)) # Facing into belt_east
	
	_router.route_entity(belt_east)
	_router.route_entity(belt_west)
	
	assert(belt_east.output_target == null, "Belts facing each other incorrectly linked!")
	assert(belt_west.output_target == null, "Belts facing each other incorrectly linked!")