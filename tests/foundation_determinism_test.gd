extends Node

## Deterministic foundation tests for replay, save snapshots, and tick restoration.

const ReplaySystemRef = preload("res://src/core/replay_system.gd")
const SaveStateRef = preload("res://src/core/save_state.gd")
const TickSchedulerRef = preload("res://src/core/tick_scheduler.gd")

var _observed_ticks: Array[int] = []

func run_tests() -> void:
	print("Running FoundationDeterminism tests...")
	_test_replay_round_trip()
	_test_save_state_round_trip()
	_test_tick_scheduler_restore_and_long_run()
	print("All FoundationDeterminism tests passed.")

func _test_replay_round_trip() -> void:
	var replay = ReplaySystemRef.new(1234)
	replay.record_action(1, "build", {"entity_id": "belt_t1"})
	replay.record_action(1, "place", {"position": Vector2i(3, 4)})
	replay.record_action(3, "remove", {"entity_id": "belt_t1"})

	var serialized = replay.serialize()
	assert(serialized["seed"] == 1234, "Replay seed was not preserved in serialization.")

	var restored = ReplaySystemRef.new()
	restored.deserialize(serialized)

	assert(restored.serialize() == serialized, "Replay serialization round-trip changed data.")
	assert(restored.get_actions_for_tick(1).size() == 2, "Tick 1 actions were not restored in order.")
	assert(restored.get_actions_for_tick(2).is_empty(), "Unexpected actions appeared on an empty tick.")

func _test_save_state_round_trip() -> void:
	var replay = ReplaySystemRef.new(77)
	replay.record_action(8, "build", {"entity_id": "miner_t1"})

	var save_state = replay.call("create_save_state", 42)
	var serialized_state = save_state.serialize()
	var restored_state = SaveStateRef.deserialize(serialized_state)

	assert(restored_state.save_version == 1, "Save version was not preserved.")
	assert(restored_state.current_tick == 42, "Current tick was not preserved in save state.")
	assert(restored_state.replay_data == save_state.replay_data, "Replay payload changed during save round-trip.")

	var restored_replay = ReplaySystemRef.new()
	restored_replay.call("restore_save_state", restored_state)
	assert(restored_replay.serialize() == replay.serialize(), "Restored replay did not match original replay state.")

func _test_tick_scheduler_restore_and_long_run() -> void:
	var scheduler = TickSchedulerRef.new()
	add_child(scheduler)

	_observed_ticks.clear()
	scheduler.register_subscriber(Callable(self, "_record_tick"))
	scheduler.start(TickSchedulerRef.Mode.MANUAL)

	for _i in range(1000):
		scheduler.manual_tick()

	assert(scheduler.get_current_tick() == 1000, "Scheduler did not advance through 1000 deterministic ticks.")
	assert(_observed_ticks.size() == 1000, "Subscriber did not receive every manual tick.")
	assert(_observed_ticks[0] == 1 and _observed_ticks[999] == 1000, "Tick sequence was not deterministic.")

	scheduler.restore_state(250, 0.0)
	scheduler.manual_tick()
	assert(scheduler.get_current_tick() == 251, "Scheduler restore state did not resume from the saved tick.")

func _record_tick(tick_number: int) -> void:
	_observed_ticks.append(tick_number)