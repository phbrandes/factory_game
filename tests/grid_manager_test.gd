extends Node

## Standalone test runner for the GridManager.
## Attach this to an empty Node2D and run the scene to execute.

var _grid: GridManager
const GridEntityRef = preload("res://src/core/grid_entity.gd")

func run_tests() -> void:
	print("Running GridManager Tests...")
	_grid = load("res://src/core/grid_manager.gd").new()
	
	_test_single_placement()
	_test_multi_tile_placement()
	_test_overlapping_placement()
	_test_removal()
	
	print("All GridManager tests passed.")

func _test_single_placement() -> void:
	_grid.clear_all()
	var belt = GridEntityRef.new("belt_t1", Vector2i(1, 1))
	
	var success = _grid.place_entity(belt, Vector2i(5, 5))
	assert(success, "Failed to place 1x1 entity on empty grid.")
	assert(_grid.get_entity_at(Vector2i(5, 5)) == belt, "Grid retrieval failed.")
	assert(_grid.get_entity_at(Vector2i(5, 6)) == null, "Grid bleed detected.")

func _test_multi_tile_placement() -> void:
	_grid.clear_all()
	# Simulate a 2x2 Assembler
	var assembler = GridEntityRef.new("assembler_t1", Vector2i(2, 2))
	
	var success = _grid.place_entity(assembler, Vector2i(10, 10))
	assert(success, "Failed to place 2x2 entity.")
	
	# Verify all 4 footprint tiles return the exact same entity reference
	assert(_grid.get_entity_at(Vector2i(10, 10)) == assembler, "Origin tile mismatch.")
	assert(_grid.get_entity_at(Vector2i(11, 10)) == assembler, "Top-right tile mismatch.")
	assert(_grid.get_entity_at(Vector2i(10, 11)) == assembler, "Bottom-left tile mismatch.")
	assert(_grid.get_entity_at(Vector2i(11, 11)) == assembler, "Bottom-right tile mismatch.")

func _test_overlapping_placement() -> void:
	_grid.clear_all()
	var smelter = GridEntityRef.new("smelter_t1", Vector2i(2, 2))
	var belt = GridEntityRef.new("belt_t1", Vector2i(1, 1))
	
	_grid.place_entity(smelter, Vector2i(0, 0))
	
	# Try placing a belt intersecting the smelter's footprint
	var success = _grid.place_entity(belt, Vector2i(1, 1))
	assert(not success, "Grid allowed overlapping placement!")
	assert(_grid.get_entity_at(Vector2i(1, 1)) == smelter, "Original entity was overwritten!")

func _test_removal() -> void:
	_grid.clear_all()
	var miner = GridEntityRef.new("miner_t1", Vector2i(2, 2))
	_grid.place_entity(miner, Vector2i(0, 0))
	
	_grid.remove_entity(miner)
	
	assert(_grid.is_area_empty(Vector2i(0, 0), Vector2i(2, 2)), "Multi-tile removal failed to clear all footprint cells.")