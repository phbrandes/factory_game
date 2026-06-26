extends Node

## Standalone test runner for CraftingComponent logic.

const InventoryComponentRef = preload("res://src/core/components/inventory_component.gd")
const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")
const CraftingComponentRef = preload("res://src/core/components/crafting_component.gd")

func run_tests() -> void:
	print("Running CraftingComponent Tests...")
	
	_test_successful_craft()
	_test_input_starvation()
	_test_output_backpressure()
	
	print("All CraftingComponent tests passed.")

func _test_successful_craft() -> void:
	var input_inv = InventoryComponentRef.new(10)
	var output_inv = InventoryComponentRef.new(10)
	var crafter = CraftingComponentRef.new(input_inv, output_inv)
	
	var recipe = RecipeResourceRef.new("smelt_iron", {"iron_ore": 1}, {"iron_plate": 1}, 2)
	crafter.set_recipe(recipe)
	
	# Load inputs
	input_inv.add_item("iron_ore", 1)
	
	assert(crafter.current_state == crafter.State.IDLE, "Initial state should be IDLE.")
	
	# Tick 1: Starts crafting, consumes input
	crafter.tick()
	assert(crafter.current_state == crafter.State.CRAFTING, "Failed to enter CRAFTING state.")
	assert(input_inv.total_items == 0, "Failed to consume inputs upfront.")
	assert(crafter.progress_ticks == 1, "Progress failed to advance.")
	
	# Tick 2: Finishes crafting, pushes to output, resets to IDLE (because no more inputs)
	crafter.tick()
	assert(output_inv.contents.get("iron_plate", 0) == 1, "Failed to produce output.")
	assert(crafter.current_state == crafter.State.IDLE, "Failed to reset to IDLE after craft.")

func _test_input_starvation() -> void:
	var input_inv = InventoryComponentRef.new(10)
	var output_inv = InventoryComponentRef.new(10)
	var crafter = CraftingComponentRef.new(input_inv, output_inv)
	
	# Requires 2 copper ore
	var recipe = RecipeResourceRef.new("smelt_copper", {"copper_ore": 2}, {"copper_plate": 1}, 5)
	crafter.set_recipe(recipe)
	
	# Provide only 1 copper ore
	input_inv.add_item("copper_ore", 1)
	
	crafter.tick()
	crafter.tick()
	
	assert(crafter.current_state == crafter.State.IDLE, "Crafter started without sufficient inputs!")
	assert(input_inv.contents["copper_ore"] == 1, "Crafter consumed partial inputs!")

func _test_output_backpressure() -> void:
	var input_inv = InventoryComponentRef.new(10)
	var output_inv = InventoryComponentRef.new(1) # Tiny output inventory!
	var crafter = CraftingComponentRef.new(input_inv, output_inv)
	
	var recipe = RecipeResourceRef.new("make_gear", {"iron_plate": 1}, {"iron_gear": 1}, 1)
	crafter.set_recipe(recipe)
	
	# Load up lots of inputs
	input_inv.add_item("iron_plate", 5)
	
	# Craft #1 (Works fine, fills the output)
	crafter.tick()
	assert(output_inv.contents["iron_gear"] == 1, "First craft failed.")
	
	# Check state immediately after Craft #1 (Since it auto-starts next craft)
	assert(crafter.current_state == crafter.State.CRAFTING, "Failed to auto-start next craft.")
	
	# Craft #2 (Finishes, but output is full)
	crafter.tick()
	
	assert(crafter.current_state == crafter.State.STALLED, "Crafter failed to enter STALLED state when output was full.")
	assert(input_inv.contents["iron_plate"] == 3, "Input for stalled craft should have been consumed.")
	assert(output_inv.total_items == 1, "Output overflowed!")
	
	# Clear the output inventory manually
	output_inv.remove_item("iron_gear", 1)
	
	# Next tick should resolve the stalled state
	crafter.tick()
	
	assert(output_inv.contents["iron_gear"] == 1, "Crafter failed to push items after stall resolved.")
	assert(crafter.current_state == crafter.State.CRAFTING, "Crafter failed to resume auto-crafting after stall resolved.")