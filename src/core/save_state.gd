class_name SaveState
extends RefCounted

## Data-only save snapshot for deterministic replay restoration.

const CURRENT_SAVE_VERSION: int = 1

var save_version: int = CURRENT_SAVE_VERSION
var current_tick: int = 0
var replay_data: Dictionary = {}

func _init(p_current_tick: int = 0, p_replay_data: Dictionary = {}, p_save_version: int = CURRENT_SAVE_VERSION) -> void:
	current_tick = p_current_tick
	replay_data = p_replay_data.duplicate(true)
	save_version = p_save_version

func serialize() -> Dictionary:
	return {
		"save_version": save_version,
		"current_tick": current_tick,
		"replay": replay_data.duplicate(true)
	}

static func deserialize(data: Dictionary) -> SaveState:
	var state = SaveState.new()
	state.save_version = int(data.get("save_version", CURRENT_SAVE_VERSION))
	state.current_tick = int(data.get("current_tick", 0))

	var replay_payload: Variant = data.get("replay", {})
	if typeof(replay_payload) == TYPE_DICTIONARY:
		state.replay_data = replay_payload.duplicate(true)

	return state