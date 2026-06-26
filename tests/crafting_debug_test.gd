extends Node

## Debug version to understand crafting timing

const InventoryComponentRef = preload("res://src/core/components/inventory_component.gd")
const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")
const CraftingComponentRef = preload("res://src/core/components/crafting_component.gd")

func _ready() -> void:
	run_tests()
	get_tree().quit()

func run_tests() -> void:
	print("=== CRAFTING DEBUG TEST ===")
	_debug_craft()

func _debug_craft() -> void:
	var input_inv = InventoryComponentRef.new(10)
	var output_inv = InventoryComponentRef.new(10)
	var crafter = CraftingComponentRef.new(input_inv, output_inv)
	
	var recipe = RecipeResourceRef.new("smelt_iron", {"iron_ore": 1}, {"iron_plate": 1}, 2)
	crafter.set_recipe(recipe)
	
	# Load inputs
	input_inv.add_item("iron_ore", 1)
	
	print("Initial state: state=%s, progress=%d" % [crafter.State.keys()[crafter.current_state], crafter.progress_ticks])
	
	# Tick 1
	print("\nTick 1:")
	crafter.tick()
	print("  After tick: state=%s, progress=%d" % [crafter.State.keys()[crafter.current_state], crafter.progress_ticks])
	print("  Input inv total: %d" % input_inv.total_items)
	print("  Output inv total: %d" % output_inv.total_items)
	print("  Expected: state=CRAFTING, progress=1")
	
	# Tick 2
	print("\nTick 2:")
	crafter.tick()
	print("  After tick: state=%s, progress=%d" % [crafter.State.keys()[crafter.current_state], crafter.progress_ticks])
	print("  Input inv total: %d" % input_inv.total_items)
	print("  Output inv total: %d (expected: 1)" % output_inv.total_items)
	print("  Output inv contents: %s" % output_inv.contents)
