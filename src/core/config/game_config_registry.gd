class_name GameConfigRegistry
extends RefCounted

## Centralized parser and repository for all game balancing data (JSON).
## Eliminates hardcoded magic numbers.

const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")

var recipes: Dictionary = {} # Maps recipe_id (String) to RecipeResource
var entity_stats: Dictionary = {} # Maps entity_id (String) to a Dictionary of stats

## Parses a raw JSON string and populates the registry.
func load_from_json_string(json_string: String) -> bool:
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		printerr("GameConfigRegistry: Failed to parse JSON. Error code: ", error)
		return false
		
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		printerr("GameConfigRegistry: JSON root must be a dictionary.")
		return false
		
	if data.has("recipes"):
		_parse_recipes(data["recipes"])
		
	if data.has("entities"):
		_parse_entities(data["entities"])
		
	return true

## Converts raw JSON dictionaries into strict RecipeResources.
func _parse_recipes(recipe_data: Dictionary) -> void:
	for recipe_id in recipe_data.keys():
		var r_data = recipe_data[recipe_id]
		
		# Type-safe casting of JSON numbers to ints for our deterministic simulation
		var inputs: Dictionary = {}
		if r_data.has("inputs"):
			for item_id in r_data["inputs"]:
				inputs[item_id] = int(r_data["inputs"][item_id])
				
		var outputs: Dictionary = {}
		if r_data.has("outputs"):
			for item_id in r_data["outputs"]:
				outputs[item_id] = int(r_data["outputs"][item_id])
				
		var ticks = int(r_data.get("ticks_to_craft", 10))
		
		var recipe = RecipeResourceRef.new(recipe_id, inputs, outputs, ticks)
		recipes[recipe_id] = recipe

## Stores raw stat dictionaries for entity initialization.
func _parse_entities(entity_data: Dictionary) -> void:
	for entity_id in entity_data.keys():
		entity_stats[entity_id] = entity_data[entity_id]

## Retrieves a loaded recipe, or null if it doesn't exist.
func get_recipe(recipe_id: String) -> RecipeResource:
	return recipes.get(recipe_id, null)

## Retrieves a specific stat for an entity, providing a safe fallback.
func get_entity_stat(entity_id: String, stat_name: String, default_value: Variant = null) -> Variant:
	if entity_stats.has(entity_id) and entity_stats[entity_id].has(stat_name):
		return entity_stats[entity_id][stat_name]
	return default_value