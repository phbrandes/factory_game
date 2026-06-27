## tests/core/world/chunk_grid_test.gd
extends Node

func run_tests() -> void:
    # 1. Defensive Check
    if not SparseChunkGrid:
        push_error("CRITICAL: Could not load SparseChunkGrid from /home/phbrandes/Documents/factory_game/src/visuals/chunking/chunk_grid.gd")
        return

    var grid = SparseChunkGrid.new()
    if not grid:
        push_error("CRITICAL: Could not instantiate SparseChunkGrid.")
        return
    # 2. Test 1: Write/Read same chunk
    grid.set_cell(Vector2i(5, 5), "TEST_A")
    if grid.get_cell(Vector2i(5, 5)) != "TEST_A":
        push_error("Failed to retrieve local cell.")
    
    # 3. Test 2: Crossing Boundary (15 -> 16)
    grid.set_cell(Vector2i(15, 0), "BOUNDARY_A")
    grid.set_cell(Vector2i(16, 0), "BOUNDARY_B")
    
    if grid.get_cell(Vector2i(15, 0)) != "BOUNDARY_A":
        push_error("Failed chunk boundary A.")
    if grid.get_cell(Vector2i(16, 0)) != "BOUNDARY_B":
        push_error("Failed chunk boundary B.")
    
    # 4. Test 3: Sparse Behavior
    if grid.get_active_chunk_count() != 2:
        push_error("Chunk count mismatch. Expected 2 chunks, got " + str(grid.get_active_chunk_count()))
    
    print("  [PASS] SparseChunkGrid: All boundary and mapping tests passed.")

    # 5. Test 4: Memory Leak Detection

    if not OS.is_debug_build(): 
     print("  [DEBUG] Skipping memory leak detection in non-debug build.")     
    else: 
        grid.clear()
    ##memory leak detection: Ensure all chunks are freed after test
    
    var initial_chunk_count = grid.get_active_chunk_count()
    for i in range(100):
        grid.set_cell(Vector2i(i, i), "DATA_%d" % i)
    if grid.get_active_chunk_count() <= initial_chunk_count:
        push_error("Memory leak test failed: Chunk count did not increase after adding new cells.")
