class_name PowerNetwork
extends RefCounted

## Manages a distinct grid of connected generators and consumers.
## Pools energy and distributes it deterministically per tick.

var network_id: String = ""
var generators: Array[PowerGeneratorComponent] = []
var consumers: Array[PowerConsumerComponent] = []

func _init(p_id: String) -> void:
	network_id = p_id

func register_generator(gen: PowerGeneratorComponent) -> void:
	if not generators.has(gen):
		generators.append(gen)

func register_consumer(con: PowerConsumerComponent) -> void:
	if not consumers.has(con):
		consumers.append(con)

## Executed by the TickScheduler or a global PowerManager
func tick() -> void:
	var total_pool: int = 0
	
	# 1. Pool all generated energy
	for gen in generators:
		total_pool += gen.get_generated_energy()
		
	# 2. Distribute sequentially to fill consumer buffers
	# To ensure perfect determinism, iteration strictly follows registration order.
	for con in consumers:
		if total_pool <= 0:
			break # Pool is empty, remaining consumers get nothing
			
		var needed = con.get_requested_energy()
		if needed > 0:
			var amount_to_give = mini(needed, total_pool)
			con.receive_energy(amount_to_give)
			total_pool -= amount_to_give