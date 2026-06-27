## tests/core/world/chunk_grid_test.gd
extends Node

const SparseChunkGrid = preload("/home/phbrandes/Documents/factory_game/src/visuals/chunking/chunk_grid.gd")

func run_tests() -> void:
	var grid = SparseChunkGrid.new()
	
	# Test 1: Write/Read same chunk
	grid.set_cell(Vector2i(5, 5), "TEST_A")
	assert(grid.get_cell(Vector2i(5, 5)) == "TEST_A", "Failed to retrieve local cell.")
	
	# Test 2: Crossing Boundary (15 -> 16)
	grid.set_cell(Vector2i(15, 0), "BOUNDARY_A")
	grid.set_cell(Vector2i(16, 0), "BOUNDARY_B")
	
	assert(grid.get_cell(Vector2i(15, 0)) == "BOUNDARY_A", "Failed chunk boundary A.")
	assert(grid.get_cell(Vector2i(16, 0)) == "BOUNDARY_B", "Failed chunk boundary B.")
	
	# Test 3: Sparse Behavior
	assert(grid.get_active_chunk_count() == 2, "Chunk count mismatch. Expected 2 chunks.")
	
	print("  [PASS] SparseChunkGrid: All boundary and mapping tests passed.")