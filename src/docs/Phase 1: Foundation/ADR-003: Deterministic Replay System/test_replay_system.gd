class_name TestReplaySystem
extends Node

## Standalone test runner for the deterministic Replay validation.
## Validates the Phase 1 "1,000 Deterministic Ticks" roadmap milestone.

const GridEntityRef = preload("res://src/core/grid_entity.gd")

func _ready() -> void:
	print("Running ReplaySystem 1,000 Tick Determinism Test...")
	
	# Phase A: Original Playthrough
	var initial_seed = 42069
	var original_grid = GridManager.new()
	var original_scheduler = TickScheduler.new()
	var original_replay = ReplaySystem.new(initial_seed)
	
	# We simulate 1000 ticks. Randomly, we place entities.
	for i in range(1000):
		original_scheduler.manual_tick()
		var current_tick = original_scheduler.get_current_tick()
		
		# Every 20 ticks, randomly place a belt somewhere
		if current_tick % 20 == 0:
			var rand_x = original_replay.rng.randi_range(-50, 50)
			var rand_y = original_replay.rng.randi_range(-50, 50)
			var pos_dict = {"x": rand_x, "y": rand_y}
			
			original_replay.record_action(current_tick, "place_belt", pos_dict)
			var belt = GridEntityRef.new("belt_t1")
			original_grid.place_entity(belt, Vector2i(rand_x, rand_y))

	# Phase B: Save State
	var save_file: Dictionary = original_replay.serialize()
	
	# Phase C: Replay Playthrough
	var replay_grid = GridManager.new()
	var replay_scheduler = TickScheduler.new()
	var replay_system = ReplaySystem.new()
	replay_system.deserialize(save_file)
	
	# Fast-forward 1000 ticks
	for i in range(1000):
		replay_scheduler.manual_tick()
		var current_tick = replay_scheduler.get_current_tick()
		
		# Check if player took actions on this tick
		var actions = replay_system.get_actions_for_tick(current_tick)
		for action in actions:
			if action.action_type == "place_belt":
				var px = action.payload["x"]
				var py = action.payload["y"]
				var belt = GridEntityRef.new("belt_t1")
				replay_grid.place_entity(belt, Vector2i(px, py))
				
	# Phase D: Validation
	_validate_identical_grids(original_grid, replay_grid)
	print("SUCCESS: 1,000 Deterministic Ticks verified. Grids match perfectly.")
	get_tree().quit()

func _validate_identical_grids(grid_a: GridManager, grid_b: GridManager) -> void:
	var keys_a = grid_a._grid.keys()
	var keys_b = grid_b._grid.keys()
	
	assert(keys_a.size() == keys_b.size(), "Grid sizes do not match after replay.")
	
	for key in keys_a:
		assert(grid_b._grid.has(key), "Replay grid missing entity at coordinate: " + str(key))
		var entity_a = grid_a._grid[key]
		var entity_b = grid_b._grid[key]
		assert(entity_a.entity_id == entity_b.entity_id, "Entity ID mismatch at coordinate: " + str(key))