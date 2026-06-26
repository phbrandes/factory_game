extends Node

## Standalone test runner for deterministic power generation and consumption.

const PowerGeneratorRef = preload("res://src/core/components/power_generator_component.gd")
const PowerConsumerRef = preload("res://src/core/components/power_consumer_component.gd")
const PowerNetworkRef = preload("res://src/core/power_network.gd")

func run_tests() -> void:
	print("Running PowerSystem Tests...")
	
	_test_sufficient_power()
	_test_deterministic_brownout()
	_test_network_pooling()
	
	print("All PowerSystem tests passed.")

func _test_sufficient_power() -> void:
	var network = PowerNetworkRef.new("grid_1")
	var generator = PowerGeneratorRef.new(100) # Generates 100/t
	var consumer = PowerConsumerRef.new(50)    # Drains 50/t. Capacity = 100.
	
	network.register_generator(generator)
	network.register_consumer(consumer)
	
	# Tick 1: Buffer fills completely (needs 100, pool has 100)
	network.tick()
	assert(consumer.buffer == 100, "Consumer failed to fill buffer.")
	
	# Machine operates
	assert(consumer.try_consume() == true, "Consumer failed to operate with full buffer.")
	assert(consumer.buffer == 50, "Buffer did not drain correctly.")
	
	# Tick 2: Buffer tops up (needs 50, pool has 100)
	network.tick()
	assert(consumer.buffer == 100, "Consumer failed to top up buffer.")

func _test_deterministic_brownout() -> void:
	var network = PowerNetworkRef.new("grid_2")
	var generator = PowerGeneratorRef.new(10) # Generates ONLY 10/t
	var consumer = PowerConsumerRef.new(20)   # Drains 20/t! Capacity = 40.
	
	network.register_generator(generator)
	network.register_consumer(consumer)
	
	# Tick 1: Generates 10. Buffer = 10. Needs 20 to run.
	network.tick()
	assert(consumer.buffer == 10, "Buffer should have 10 energy.")
	assert(consumer.try_consume() == false, "Machine magically operated without enough power!")
	
	# Tick 2: Generates 10. Buffer = 20. Needs 20 to run.
	network.tick()
	assert(consumer.buffer == 20, "Buffer should have 20 energy.")
	assert(consumer.try_consume() == true, "Machine failed to operate after accumulating power.")
	
	# After consuming, buffer is 0. 
	# This proves that exactly every 2nd tick, the machine will run. Deterministic brownout!
	assert(consumer.buffer == 0, "Buffer did not reset.")

func _test_network_pooling() -> void:
	var network = PowerNetworkRef.new("grid_3")
	# Three small generators making 10 each
	for i in range(3):
		network.register_generator(PowerGeneratorRef.new(10))
		
	var consumer = PowerConsumerRef.new(30) # Needs exactly 30 to run
	network.register_consumer(consumer)
	
	network.tick()
	
	# If pooling works, total pool was 30, and buffer should have exactly 30.
	assert(consumer.buffer == 30, "Network failed to pool multiple generators.")
	assert(consumer.try_consume() == true, "Pooled energy was insufficient.")