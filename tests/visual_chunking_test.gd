extends Node

## Standalone test runner verifying mathematical chunking and process culling.

const VisualChunkManagerRef = preload("res://src/visuals/chunking/visual_chunk_manager.gd")
const VisualChunkRef = preload("res://src/visuals/chunking/visual_chunk.gd")

func run_tests() -> void:
	print("Running VisualChunking Tests...")
	
	_test_chunk_coordinate_math()
	_test_node_parenting()
	_test_process_culling()
	
	print("All VisualChunking tests passed.")

func _test_chunk_coordinate_math() -> void:
	# Positive Coordinates
	assert(VisualChunkManagerRef.get_chunk_coord(Vector2i(0, 0)) == Vector2i(0, 0), "Origin math failed.")
	assert(VisualChunkManagerRef.get_chunk_coord(Vector2i(15, 15)) == Vector2i(0, 0), "Inner bound math failed.")
	assert(VisualChunkManagerRef.get_chunk_coord(Vector2i(16, 16)) == Vector2i(1, 1), "Chunk boundary crossover failed.")
	
	# Negative Coordinates (Crucial: integer division in C/C++ truncates toward zero, we need floor())
	assert(VisualChunkManagerRef.get_chunk_coord(Vector2i(-1, -1)) == Vector2i(-1, -1), "Negative math failed.")
	assert(VisualChunkManagerRef.get_chunk_coord(Vector2i(-16, -16)) == Vector2i(-1, -1), "Negative bound math failed.")
	assert(VisualChunkManagerRef.get_chunk_coord(Vector2i(-17, -17)) == Vector2i(-2, -2), "Negative boundary crossover failed.")

func _test_node_parenting() -> void:
	var manager = VisualChunkManagerRef.new()
	add_child(manager)
	
	var mock_visual_a = Node2D.new()
	var mock_visual_b = Node2D.new()
	
	# Node A at grid (5, 5) -> Chunk (0, 0)
	manager.add_visual_node(mock_visual_a, Vector2i(5, 5))
	
	# Node B at grid (20, 5) -> Chunk (1, 0)
	manager.add_visual_node(mock_visual_b, Vector2i(20, 5))
	
	assert(manager._chunks.has(Vector2i(0, 0)), "Chunk (0,0) not created.")
	assert(manager._chunks.has(Vector2i(1, 0)), "Chunk (1,0) not created.")
	
	assert(mock_visual_a.get_parent() == manager._chunks[Vector2i(0, 0)], "Node A parented to wrong chunk.")
	assert(mock_visual_b.get_parent() == manager._chunks[Vector2i(1, 0)], "Node B parented to wrong chunk.")

func _test_process_culling() -> void:
	var manager = VisualChunkManagerRef.new()
	add_child(manager)
	
	var mock_visual = Node2D.new()
	manager.add_visual_node(mock_visual, Vector2i(0, 0))
	var chunk = manager._chunks[Vector2i(0, 0)]
	
	# Define bounds that EXCLUDE Chunk (0,0). E.g., camera is looking at Chunk (5,5)
	manager.update_active_chunks(Vector2i(5, 5), Vector2i(6, 6))
	
	assert(chunk.visible == false, "Chunk failed to turn invisible when culled.")
	assert(chunk.process_mode == Node.PROCESS_MODE_DISABLED, "Chunk failed to disable processing when culled.")
	
	# Define bounds that INCLUDE Chunk (0,0)
	manager.update_active_chunks(Vector2i(-1, -1), Vector2i(1, 1))
	
	assert(chunk.visible == true, "Chunk failed to become visible when un-culled.")
	assert(chunk.process_mode == Node.PROCESS_MODE_INHERIT, "Chunk failed to resume processing when un-culled.")