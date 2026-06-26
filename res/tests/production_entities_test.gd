extends Node

## Standalone test runner for ProductionEntity and MinerEntity integration.

const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")
const ProductionEntityRef = preload("res://src/core/production_entity.gd")
const MinerEntityRef = preload("res://src/core/miner_entity.gd")

func run_tests() -> void:
	print("Running Production Entities Tests...")
	
	_test_production_entity_integration()
	_test_miner_entity_generation()
	
	print("All Production Entities tests passed.")

func _test_production_entity_integration() -> void:
	# 10 input cap, 10 output cap
	var furnace = ProductionEntityRef.new("furnace_t1", 10, 10) 
	var recipe = RecipeResourceRef.new("smelt_iron", {"iron_ore": 1}, {"iron_plate": 1}, 2)
	furnace.set_recipe(recipe)
	
	# Simulate a belt pushing ore into the furnace
	assert(furnace.can_accept_item() == true, "Furnace should accept items when empty.")
	assert(furnace.receive_item("iron_ore") == true, "Furnace failed to receive item.")
	
	# Tick 1: Consumes input, starts crafting
	furnace.tick()
	assert(furnace.crafter.current_state == furnace.crafter.State.CRAFTING, "Furnace failed to start crafting.")
	assert(furnace.input_inventory.total_items == 0, "Furnace did not consume input from its inventory.")
	
	# Tick 2: Finishes craft, pushes to output
	furnace.tick()
	assert(furnace.output_inventory.contents.has("iron_plate"), "Furnace failed to produce output.")
	
	# Simulate an extractor pulling the plate out
	assert(furnace.can_provide_item("iron_plate", 1) == true, "Furnace cannot provide output.")
	assert(furnace.extract_item("iron_plate", 1) == true, "Failed to extract output.")
	assert(furnace.output_inventory.total_items == 0, "Output inventory not empty after extraction.")

func _test_miner_entity_generation() -> void:
	# 5 output cap
	var miner = MinerEntityRef.new("miner_t1", 5)
	
	# A mining recipe has NO inputs, 1 output, takes 1 tick
	var coal_node = RecipeResourceRef.new("mine_coal", {}, {"coal": 1}, 1)
	miner.set_mining_resource(coal_node)
	
	# Ensure it rejects inputs
	assert(miner.can_accept_item() == false, "Miner should never accept logistical inputs.")
	
	# Tick 1: Generates 1 coal
	miner.tick()
	assert(miner.output_inventory.contents.get("coal", 0) == 1, "Miner failed to generate resource.")
	
	# Fast forward to fill the miner
	for i in range(10):
		miner.tick()
		
	# Miner capacity is 5. It should stop generating.
	assert(miner.output_inventory.total_items == 5, "Miner overflowed its maximum capacity!")
	assert(miner.crafter.current_state == miner.crafter.State.STALLED, "Miner failed to stall when output filled.")
	
	# Extract 1 item. It should resume mining.
	miner.extract_item("coal", 1)
	miner.tick()
	assert(miner.output_inventory.total_items == 5, "Miner failed to resume and fill space after extraction.")