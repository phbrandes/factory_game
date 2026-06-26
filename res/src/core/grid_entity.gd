class_name GridEntity
extends RefCounted

## Base class for any purely logical object that occupies the grid.
## Simulation only. No visual dependencies.

var entity_id: String = ""
var grid_position: Vector2i = Vector2i.ZERO
var size: Vector2i = Vector2i.ONE

func _init(p_id: String, p_size: Vector2i = Vector2i.ONE) -> void:
	entity_id = p_id
	size = p_size