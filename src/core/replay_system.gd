extends RefCounted

## Manages the deterministic RNG and chronologically logs player inputs.

var _seed: int = 0
var rng: RandomNumberGenerator
var _actions: Array[ReplayAction] = []
var save_version: int = 1

func _init(p_seed: int = 0) -> void:
	rng = RandomNumberGenerator.new()
	if p_seed == 0:
		rng.randomize()
		_seed = rng.seed
	else:
		_seed = p_seed
		rng.seed = _seed

## Records an action to the timeline. Must be called in chronological order.
func record_action(tick: int, action_type: String, payload: Dictionary = {}) -> void:
	var action = ReplayAction.new(tick, action_type, payload)
	_actions.append(action)

## Retrieves all actions that occurred on a specific tick.
func get_actions_for_tick(tick: int) -> Array[ReplayAction]:
	var result: Array[ReplayAction] = []
	# Optimized for chronological execution: actions are mostly read from the front
	for action in _actions:
		if action.tick == tick:
			result.append(action)
		elif action.tick > tick:
			break # Since it's chronological, we can stop searching early
	return result

## Serializes the entire replay log into a JSON-safe dictionary.
func serialize() -> Dictionary:
	var serialized_actions: Array = []
	for action in _actions:
		serialized_actions.append(action.serialize())
		
	return {
		"save_version": save_version,
		"seed": _seed,
		"actions": serialized_actions
	}

## Deserializes save data into the replay system.
func deserialize(data: Dictionary) -> void:
	_actions.clear()
	
	# Save Versioning check mandated by 01_SYSTEM_PROMPT.md
	if data.has("save_version"):
		save_version = data["save_version"]
		# Migration functions would go here if save_version < CURRENT_VERSION
		
	if data.has("seed"):
		_seed = data["seed"]
		rng.seed = _seed
		
	if data.has("actions"):
		for action_data in data["actions"]:
			_actions.append(ReplayAction.deserialize(action_data))