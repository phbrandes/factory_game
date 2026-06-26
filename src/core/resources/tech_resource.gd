class_name TechResource
extends Resource

## Pure data definition of a single unlockable technology node.

@export var tech_id: String = ""
@export var prerequisites: Array[String] = [] # Array of tech_ids required before this can be researched
@export var cost: Dictionary = {} # Map of item_id (String) to total quantity required (int)
@export var unlocks_recipes: Array[String] = [] # Array of recipe_ids unlocked by this tech

func _init(p_id: String = "", p_prereqs: Array[String] = [], p_cost: Dictionary = {}, p_unlocks: Array[String] = []) -> void:
	tech_id = p_id
	prerequisites = p_prereqs
	cost = p_cost
	unlocks_recipes = p_unlocks