class_name CombatComponents
extends RefCounted

## Health and Targeting Logic

class HealthComponent:
	var max_health: int
	var current_health: int
	
	func _init(hp: int) -> void:
		max_health = hp
		current_health = hp
		
	func take_damage(amount: int) -> void:
		current_health -= amount
	
	func is_dead() -> bool:
		return current_health <= 0

class TargetingComponent:
	var range_tiles: int
	
	func _init(p_range: int) -> void:
		range_tiles = p_range
		
	## Deterministic targeting: sort by age then health
	func get_best_target(my_pos: Vector2i, potential_targets: Array) -> Object:
		var targets_in_range = potential_targets.filter(func(t): 
			return (t.grid_position - my_pos).length_squared() <= range_tiles * range_tiles)
		
		if targets_in_range.is_empty():
			return null
			
		targets_in_range.sort_custom(func(a, b):
			if a.creation_tick != b.creation_tick:
				return a.creation_tick < b.creation_tick
			return a.health.current_health < b.health.current_health
		)
		return targets_in_range[0]