class_name ReplayAction
extends RefCounted

## Represents a single deterministic action taken by the player on a specific tick.

var tick: int = 0
var action_type: String = ""
var payload: Dictionary = {}

func _init(p_tick: int, p_type: String, p_payload: Dictionary = {}) -> void:
	tick = p_tick
	action_type = p_type
	payload = p_payload

## Converts the action into a JSON-compatible dictionary for saving.
func serialize() -> Dictionary:
	return {
		"t": tick,
		"type": action_type,
		"data": payload
	}

## Reconstructs an action from loaded save data.
static func deserialize(data: Dictionary) -> ReplayAction:
	var action = ReplayAction.new(0, "")
	if data.has("t"): action.tick = data["t"]
	if data.has("type"): action.action_type = data["type"]
	if data.has("data"): action.payload = data["data"]
	return action