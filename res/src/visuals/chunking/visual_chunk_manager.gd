class_name VisualChunkManager
extends Node2D

## Manages the spatial partitioning of visual nodes for performance culling.

const CHUNK_SIZE: int = 16

var _chunks: Dictionary = {} # Maps Vector2i (Chunk Coord) to VisualChunk nodes

## Converts a raw grid coordinate into a chunk coordinate using safe floor division.
static func get_chunk_coord(grid_pos: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(float(grid_pos.x) / CHUNK_SIZE)),
		int(floor(float(grid_pos.y) / CHUNK_SIZE))
	)

## Adds a visual node to the correct chunk, creating the chunk if it doesn't exist.
func add_visual_node(visual_node: Node2D, grid_pos: Vector2i) -> void:
	var c_coord = get_chunk_coord(grid_pos)
	var chunk = _get_or_create_chunk(c_coord)
	chunk.add_child(visual_node)

## Retrieves a chunk, dynamically creating it if needed.
func _get_or_create_chunk(c_coord: Vector2i) -> VisualChunk:
	if _chunks.has(c_coord):
		return _chunks[c_coord]
		
	var new_chunk = VisualChunk.new(c_coord)
	_chunks[c_coord] = new_chunk
	add_child(new_chunk)
	return new_chunk

## Updates which chunks are actively processing based on a bounding box (camera view).
## bounds_min and bounds_max are in Chunk Coordinates.
func update_active_chunks(bounds_min: Vector2i, bounds_max: Vector2i) -> void:
	for c_coord in _chunks.keys():
		var chunk: VisualChunk = _chunks[c_coord]
		
		# Check if the chunk falls within the active bounds
		var is_active = (
			c_coord.x >= bounds_min.x and c_coord.x <= bounds_max.x and
			c_coord.y >= bounds_min.y and c_coord.y <= bounds_max.y
		)
		
		chunk.set_active(is_active)