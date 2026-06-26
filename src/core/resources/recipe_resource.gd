class_name RecipeResource
extends Resource

## Pure data definition of a production transformation.

@export var recipe_id: String = ""
@export var inputs: Dictionary = {}  # Map of item_id (String) to quantity (int)
@export var outputs: Dictionary = {} # Map of item_id (String) to quantity (int)
@export var ticks_to_craft: int = 10 # Defaults to 1 second at 10 TPS

func _init(p_id: String = "", p_inputs: Dictionary = {}, p_outputs: Dictionary = {}, p_ticks: int = 10) -> void:
	recipe_id = p_id
	inputs = p_inputs
	outputs = p_outputs
	ticks_to_craft = p_ticks