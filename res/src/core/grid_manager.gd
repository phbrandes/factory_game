class_name GridManager
extends RefCounted

## Pure data representation of the factory floor.
## Uses a spatial dictionary for O(1) lookups and infinite expansion.

# Maps Vector2i to GridEntity references
var _grid: Dictionary = {}

## Returns true if a specific cell has no entity.
func is_cell_empty(pos: Vector2i) -> bool:
	return not _grid.has(pos)

## Returns true if an entire NxM footprint is free.
func is_area_empty(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			if not is_cell_empty(pos + Vector2i(x, y)):
				return false
	return true

## Attempts to place an entity. Returns false if blocked.
func place_entity(entity: GridEntity, pos: Vector2i) -> bool:
	if not is_area_empty(pos, entity.size):
		return false
		
	entity.grid_position = pos
	
	# Register all cells the entity occupies
	for x in range(entity.size.x):
		for y in range(entity.size.y):
			_grid[pos + Vector2i(x, y)] = entity
			
	return true

## Returns the entity at the given position, or null if empty.
func get_entity_at(pos: Vector2i) -> GridEntity:
	return _grid.get(pos, null)

## Removes an entity and clears its entire footprint from the grid.
func remove_entity(entity: GridEntity) -> void:
	var pos: Vector2i = entity.grid_position
	for x in range(entity.size.x):
		for y in range(entity.size.y):
			_grid.erase(pos + Vector2i(x, y))

## Clears the entire grid (used for loading saves/replays).
func clear_all() -> void:
	_grid.clear()