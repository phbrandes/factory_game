class_name VisualChunk
extends Node2D

## A spatial container for visual nodes to allow batch culling and processing.

var chunk_coord: Vector2i

func _init(p_coord: Vector2i) -> void:
	chunk_coord = p_coord
	name = "Chunk_" + str(chunk_coord.x) + "_" + str(chunk_coord.y)

## Toggles rendering and 60 FPS processing for this chunk and all children.
func set_active(active: bool) -> void:
	visible = active
	if active:
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		process_mode = Node.PROCESS_MODE_DISABLED