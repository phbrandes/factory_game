class_name LogisticsRouter
extends RefCounted

## Handles the automatic linking of grid entities based on placement and direction.
## Pure data logic.

var grid: GridManager

func _init(p_grid: GridManager) -> void:
	grid = p_grid

## Scans the immediate area around a newly placed entity and attempts to form logical links.
func route_entity(entity: GridEntity) -> void:
	# For Phase 2, we specifically handle routing BeltSegments.
	if entity is BeltSegment:
		_route_belt_output(entity)
		_route_incoming_belts(entity)

## Checks the tile ahead of the belt and links to it if compatible.
func _route_belt_output(belt: BeltSegment) -> void:
	var output_pos = belt.grid_position + belt.facing_direction
	var target_entity = grid.get_entity_at(output_pos)
	
	if target_entity != null:
		# Check if the target can accept items.
		if target_entity.has_method("can_accept_item") and target_entity.has_method("receive_item"):
			
			# Prevent head-to-head collisions (belts facing directly into each other)
			if target_entity is BeltSegment:
				if target_entity.facing_direction == GridDirection.get_opposite(belt.facing_direction):
					return # Do not link
			
			belt.output_target = target_entity

## Checks adjacent tiles behind/beside the new belt to see if existing belts should link TO this new one.
func _route_incoming_belts(new_belt: BeltSegment) -> void:
	var check_positions = [
		new_belt.grid_position + GridDirection.NORTH,
		new_belt.grid_position + GridDirection.SOUTH,
		new_belt.grid_position + GridDirection.EAST,
		new_belt.grid_position + GridDirection.WEST
	]
	
	for pos in check_positions:
		var neighbor = grid.get_entity_at(pos)
		if neighbor is BeltSegment:
			# If the neighbor is pointing exactly at the new belt's position
			if neighbor.grid_position + neighbor.facing_direction == new_belt.grid_position:
				# Re-evaluate the neighbor's output to link to the new belt
				_route_belt_output(neighbor)