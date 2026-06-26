class_name CraftingComponent
extends RefCounted

## Pure data component managing tick-based item transformations.
## Acts as a bridge between an input InventoryComponent and an output InventoryComponent.

enum State {
	IDLE,       # Waiting for inputs
	CRAFTING,   # Actively processing (inputs consumed)
	STALLED     # Finished, but output inventory is full
}

var current_state: State = State.IDLE
var active_recipe: RecipeResource
var progress_ticks: int = 0

var input_inventory: InventoryComponent
var output_inventory: InventoryComponent

func _init(p_input: InventoryComponent, p_output: InventoryComponent) -> void:
	input_inventory = p_input
	output_inventory = p_output

## Assigns a new recipe. Resets current progress.
func set_recipe(recipe: RecipeResource) -> void:
	active_recipe = recipe
	_reset_craft()

## Called by TickScheduler. Advances the state machine.
func tick() -> void:
	if active_recipe == null:
		return
		
	match current_state:
		State.IDLE:
			_try_start_craft()
		State.CRAFTING:
			_process_craft()
		State.STALLED:
			_try_finish_craft()

## Checks if inputs are met. If so, consumes them and starts crafting.
func _try_start_craft() -> void:
	# Verify we have all required inputs
	for item_id in active_recipe.inputs:
		var required_amount = active_recipe.inputs[item_id]
		if input_inventory.contents.get(item_id, 0) < required_amount:
			return # Missing inputs, remain IDLE
			
	# Consume inputs
	for item_id in active_recipe.inputs:
		var amount = active_recipe.inputs[item_id]
		input_inventory.remove_item(item_id, amount)
		
	current_state = State.CRAFTING
	progress_ticks = 0
	# Immediately process the first tick of crafting in the same cycle
	_process_craft()

## Advances the progress bar.
func _process_craft() -> void:
	progress_ticks += 1
	if progress_ticks >= active_recipe.ticks_to_craft:
		current_state = State.STALLED
		_try_finish_craft() # Immediately try to output

## Attempts to push crafted items to the output inventory.
func _try_finish_craft() -> void:
	# Check if we have space for ALL outputs
	var required_space = 0
	for item_id in active_recipe.outputs:
		required_space += active_recipe.outputs[item_id]
		
	if not output_inventory.has_space_for(required_space):
		return # Remain STALLED
		
	# Space exists! Generate outputs.
	for item_id in active_recipe.outputs:
		var amount = active_recipe.outputs[item_id]
		output_inventory.add_item(item_id, amount)
		
	_reset_craft()
	
	# Immediately attempt to start the next craft so we don't lose a tick
	_try_start_craft() 

func _reset_craft() -> void:
	current_state = State.IDLE
	progress_ticks = 0

## Helper for the UI/Rendering layer
func get_progress_ratio() -> float:
	if active_recipe == null or active_recipe.ticks_to_craft == 0:
		return 0.0
	if current_state == State.STALLED:
		return 1.0
	return float(progress_ticks) / float(active_recipe.ticks_to_craft)