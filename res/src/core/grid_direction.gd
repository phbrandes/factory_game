class_name GridDirection
extends RefCounted

## Universal constants for grid-based orientation and movement.

const NORTH = Vector2i(0, -1)
const SOUTH = Vector2i(0, 1)
const EAST  = Vector2i(1, 0)
const WEST  = Vector2i(-1, 0)

const ALL = [NORTH, SOUTH, EAST, WEST]

## Helper to rotate a direction 90 degrees clockwise
static func rotate_cw(dir: Vector2i) -> Vector2i:
	if dir == NORTH: return EAST
	if dir == EAST:  return SOUTH
	if dir == SOUTH: return WEST
	if dir == WEST:  return NORTH
	return dir

## Helper to get the opposite direction
static func get_opposite(dir: Vector2i) -> Vector2i:
	return dir * -1