class_name PowerGeneratorComponent
extends RefCounted

## Pure data component that generates a fixed amount of integer energy per tick.

var generation_per_tick: int = 0
var is_active: bool = true

func _init(p_generation: int) -> void:
	generation_per_tick = p_generation

## Returns the energy generated this tick.
func get_generated_energy() -> int:
	if is_active:
		return generation_per_tick
	return 0