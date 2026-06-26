class_name FlowField
extends RefCounted

## Pure data representation of a navigation field for enemy AI.

var grid: GridManager
var target_pos: Vector2i
var distances: Dictionary = {} # Vector2i : int
var vectors: Dictionary = {}   # Vector2i : Vector2i (Normalized)

func _init(p_grid: GridManager, p_target: Vector2i) -> void:
	grid = p_grid
	target_pos = p_target
	_generate()

## BFS Propagation from target
func _generate() -> void:
	var queue = [target_pos]
	distances[target_pos] = 0
	
	var head = 0
	while head < queue.size():
		var current = queue[head]
		head += 1
		
		var current_dist = distances[current]
		
		# Neighbors (4-way)
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor = current + dir
			if not distances.has(neighbor) and grid.is_walkable(neighbor):
				distances[neighbor] = current_dist + 1
				queue.append(neighbor)
	
	_calculate_vectors()

## Convert distances to direction vectors
func _calculate_vectors() -> void:
	for pos in distances.keys():
		var best_neighbor = pos
		var min_dist = distances[pos]
		
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor = pos + dir
			if distances.has(neighbor) and distances[neighbor] < min_dist:
				min_dist = distances[neighbor]
				best_neighbor = neighbor
		
		vectors[pos] = (best_neighbor - pos)

func get_direction(pos: Vector2i) -> Vector2i:
	return vectors.get(pos, Vector2i.ZERO)