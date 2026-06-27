extends RefCounted

## Manages the deterministic RNG and chronologically logs player inputs.

const SaveStateRef = preload("res://src/core/save_state.gd")

const CURRENT_SAVE_VERSION: int = 1

var _seed: int = 0
var rng: RandomNumberGenerator
var _actions: Array[ReplayAction] = []
var save_version: int = CURRENT_SAVE_VERSION

func _init(p_seed: int = 0) -> void:
	rng = RandomNumberGenerator.new()
	_seed = p_seed
	rng.seed = _seed

func get_seed() -> int:
	return _seed

func get_action_count() -> int:
	return _actions.size()

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

## Creates a data-only save snapshot for the replay timeline.
func create_save_state(current_tick: int) -> Object:
	return SaveStateRef.new(current_tick, serialize(), save_version)

## Deserializes save data into the replay system.
func deserialize(data: Dictionary) -> void:
	_actions.clear()
	
	save_version = int(data.get("save_version", CURRENT_SAVE_VERSION))
	_seed = int(data.get("seed", 0))
	rng.seed = _seed

	var actions_data: Array = data.get("actions", [])
	for action_data in actions_data:
		if typeof(action_data) == TYPE_DICTIONARY:
			_actions.append(ReplayAction.deserialize(action_data))

## Restores the replay state from a save snapshot.
func restore_save_state(state: Object) -> void:
	var replay_payload: Variant = state.get("replay_data")
	if typeof(replay_payload) == TYPE_DICTIONARY:
		deserialize(replay_payload)
	else:
		_actions.clear()

	var save_version_value: Variant = state.get("save_version")
	if save_version_value != null:
		save_version = int(save_version_value)
	else:
		save_version = CURRENT_SAVE_VERSION