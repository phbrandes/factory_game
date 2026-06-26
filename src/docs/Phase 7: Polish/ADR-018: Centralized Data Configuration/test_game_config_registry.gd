class_name TestGameConfigRegistry
extends Node

## Standalone test runner verifying JSON parsing and stat retrieval.

const GameConfigRegistryRef = preload("res://src/core/config/game_config_registry.gd")

func _ready() -> void:
	print("Running GameConfigRegistry Tests...")
	
	_test_json_parsing_and_recipes()
	_test_entity_stat_retrieval()
	
	print("All GameConfigRegistry tests passed.")
	get_tree().quit()

func _test_json_parsing_and_recipes() -> void:
	var registry = GameConfigRegistryRef.new()
	
	var mock_json = """
	{
		"recipes": {
			"smelt_iron": {
				"inputs": {"iron_ore": 1},
				"outputs": {"iron_plate": 1},
				"ticks_to_craft": 20
			}
		}
	}
	"""
	
	var success = registry.load_from_json_string(mock_json)
	assert(success == true, "Registry failed to parse valid JSON.")
	
	var recipe = registry.get_recipe("smelt_iron")
	assert(recipe != null, "Failed to instantiate recipe from JSON.")
	assert(recipe.ticks_to_craft == 20, "Failed to parse crafting ticks.")
	assert(recipe.inputs.has("iron_ore") and recipe.inputs["iron_ore"] == 1, "Failed to parse inputs.")

func _test_entity_stat_retrieval() -> void:
	var registry = GameConfigRegistryRef.new()
	
	var mock_json = """
	{
		"entities": {
			"furnace_t1": {
				"health": 100,
				"input_capacity": 50
			}
		}
	}
	"""
	registry.load_from_json_string(mock_json)
	
	# Test valid stats
	var hp = registry.get_entity_stat("furnace_t1", "health", 0)
	assert(hp == 100, "Failed to retrieve existing entity stat.")
	
	var cap = registry.get_entity_stat("furnace_t1", "input_capacity", 0)
	assert(cap == 50, "Failed to retrieve existing entity stat.")
	
	# Test fallback logic for missing stat
	var missing_stat = registry.get_entity_stat("furnace_t1", "power_drain", 5)
	assert(missing_stat == 5, "Registry failed to return default value for missing stat.")
	
	# Test fallback logic for completely missing entity
	var missing_entity = registry.get_entity_stat("fake_machine", "health", 10)
	assert(missing_entity == 10, "Registry failed to return default value for missing entity.")