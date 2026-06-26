extends Node

const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")
const ProductionEntityRef = preload("res://src/core/production_entity.gd")
const PowerConsumerRef = preload("res://src/core/components/power_consumer_component.gd")

func run_tests() -> void:
	print("Running PoweredProduction Tests...")
	_test_powered_crafting_stall()
	print("All PoweredProduction tests passed.")

func _test_powered_crafting_stall() -> void:
	# Power: Needs 10 per tick, capacity 20.
	var consumer = PowerConsumerRef.new(10, 2)
	var furnace = ProductionEntityRef.new("furnace", 10, 10, Vector2i.ONE, consumer)
	var recipe = RecipeResourceRef.new("smelt", {"ore": 1}, {"plate": 1}, 2)
	furnace.set_recipe(recipe)
	
	furnace.receive_item("ore")
	
	# Manually fill power buffer to 10 (enough for 1 tick)
	consumer.receive_energy(10)
	
	# Tick 1: Consumes ore, starts crafting, drains 10 power
	furnace.tick()
	assert(furnace.crafter.current_state == furnace.crafter.State.CRAFTING, "Should be crafting.")
	assert(consumer.buffer == 0, "Power should be drained.")
	assert(furnace.crafter.progress_ticks == 1, "Progress should advance.")
	
	# Tick 2: NO POWER. Machine should stall.
	furnace.tick()
	assert(furnace.crafter.progress_ticks == 1, "Machine progressed despite no power!")
	
	# Provide power
	consumer.receive_energy(10)
	
	# Tick 3: Has power, finishes crafting
	furnace.tick()
	assert(furnace.crafter.current_state == furnace.crafter.State.IDLE, "Craft should have finished.")
	assert(furnace.output_inventory.total_items == 1, "Output should exist.")