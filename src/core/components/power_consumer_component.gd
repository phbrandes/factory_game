class_name PowerConsumerComponent
extends RefCounted

## Pure data component managing an internal energy buffer.
## Machines must successfully consume energy from this buffer to operate.

var buffer: int = 0
var buffer_capacity: int = 0
var drain_per_tick: int = 0

func _init(p_drain: int, p_capacity_multiplier: int = 2) -> void:
	drain_per_tick = p_drain
	# Standard capacity is slightly higher than drain to allow smooth operation
	buffer_capacity = p_drain * p_capacity_multiplier

## Calculates how much energy this component wants from the network.
func get_requested_energy() -> int:
	return buffer_capacity - buffer

## Receives energy from the power network.
func receive_energy(amount: int) -> void:
	buffer = mini(buffer + amount, buffer_capacity)

## Attempts to consume the required energy for one tick of operation.
## Returns true if successful, false if there is a blackout/brownout.
func try_consume() -> bool:
	if buffer >= drain_per_tick:
		buffer -= drain_per_tick
		return true
	return false