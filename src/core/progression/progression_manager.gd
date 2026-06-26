class_name ProgressionManager
extends RefCounted

## Manages the state of the player's technology unlocks and active research.

var unlocked_techs: Array[String] = []
var active_research: TechResource = null
var research_progress: Dictionary = {} # Tracks accumulated items for active research

## Attempts to set a new technology as the active research target.
func set_active_research(tech: TechResource) -> bool:
	if is_unlocked(tech.tech_id):
		return false
		
	# Check prerequisites
	for prereq in tech.prerequisites:
		if not is_unlocked(prereq):
			return false
			
	active_research = tech
	research_progress.clear()
	
	# Initialize progress tracking
	for item_id in active_research.cost:
		research_progress[item_id] = 0
		
	return true

## Returns true if the tech is fully unlocked.
func is_unlocked(tech_id: String) -> bool:
	return unlocked_techs.has(tech_id)

## Returns true if a specific item is needed for the current research.
func needs_item(item_id: String) -> bool:
	if active_research == null:
		return false
	if not active_research.cost.has(item_id):
		return false
	return research_progress.get(item_id, 0) < active_research.cost[item_id]

## Adds progress and checks for tech completion.
func add_progress(item_id: String, amount: int = 1) -> void:
	if not needs_item(item_id):
		return
		
	research_progress[item_id] += amount
	_check_completion()

func _check_completion() -> void:
	if active_research == null:
		return
		
	for item_id in active_research.cost:
		if research_progress.get(item_id, 0) < active_research.cost[item_id]:
			return # Still needs more of this item
			
	# All costs met!
	unlocked_techs.append(active_research.tech_id)
	active_research = null
	research_progress.clear()