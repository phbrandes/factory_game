## src/core/visuals/chunking/chunk_grid.gd
class_name SparseChunkGrid
extends RefCounted

const CHUNK_SIZE := 16

var _chunks: Dictionary = {} # Vector2i (ChunkCoord) : Dictionary (CellData)

func _to_chunk_coord(global_pos: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(float(global_pos.x) / CHUNK_SIZE)),
		int(floor(float(global_pos.y) / CHUNK_SIZE))
	)

func _to_local_coord(global_pos: Vector2i) -> Vector2i:
	return Vector2i(
		posmod(global_pos.x, CHUNK_SIZE),
		posmod(global_pos.y, CHUNK_SIZE)
	)

func set_cell(pos: Vector2i, data: Variant) -> void:
	var chunk_coord := _to_chunk_coord(pos)
	if not _chunks.has(chunk_coord):
		_chunks[chunk_coord] = {}
	
	var local := _to_local_coord(pos)
	_chunks[chunk_coord][local] = data

func get_cell(pos: Vector2i) -> Variant:
	var chunk_coord := _to_chunk_coord(pos)
	if not _chunks.has(chunk_coord):
		return null
	
	return _chunks[chunk_coord].get(_to_local_coord(pos))

func get_active_chunk_count() -> int:
	return _chunks.size()