extends Node

## Standalone test runner for BeltSegment array shifting and logistics logic.

func run_tests() -> void:
	print("Running BeltSegment Tests...")
	
	_test_internal_shifting()
	_test_backpressure_stacking()
	_test_cross_segment_transfer()
	
	print("All BeltSegment tests passed.")

func _test_internal_shifting() -> void:
	var segment = load("res://src/core/belt_segment.gd").new("belt_t1", 3)
	
	# Insert iron ore at index 0
	assert(segment.receive_item("iron_ore") == true, "Failed to receive item into empty belt.")
	assert(segment.items == ["iron_ore", "", ""], "Initial placement incorrect.")
	
	segment.tick()
	assert(segment.items == ["", "iron_ore", ""], "Item failed to shift to index 1.")
	
	segment.tick()
	assert(segment.items == ["", "", "iron_ore"], "Item failed to shift to index 2.")
	
	# Tick at end of line with no target. Item should remain at index 2.
	segment.tick()
	assert(segment.items == ["", "", "iron_ore"], "Item vanished off the end of the belt!")

func _test_backpressure_stacking() -> void:
	var segment = load("res://src/core/belt_segment.gd").new("belt_t1", 3)
	
	segment.receive_item("A")
	segment.tick()
	segment.receive_item("B")
	segment.tick()
	segment.receive_item("C")
	
	# Current state: ["C", "B", "A"]. 'A' is at the end of the belt.
	assert(segment.items == ["C", "B", "A"], "Items failed to queue up.")
	
	# Because there is no output_target, they are blocked. 
	# Ticking should do absolutely nothing (no overwrites, no shifts).
	segment.tick()
	assert(segment.items == ["C", "B", "A"], "Backpressure caused data corruption or shifting over occupied slots.")
	
	# Belt is full. It must reject new items.
	assert(segment.can_accept_item() == false, "Belt accepted an item while completely full!")

func _test_cross_segment_transfer() -> void:
	var belt_a = load("res://src/core/belt_segment.gd").new("belt_a", 2)
	var belt_b = load("res://src/core/belt_segment.gd").new("belt_b", 2)
	
	# Link A to B
	belt_a.output_target = belt_b
	
	belt_a.receive_item("copper_ore")
	
	# Tick 1: Ore moves to A[1]
	belt_a.tick()
	belt_b.tick()
	assert(belt_a.items == ["", "copper_ore"], "Belt A shift failed.")
	
	# Tick 2: Ore transfers to B[0]
	belt_a.tick()
	belt_b.tick()
	assert(belt_a.items == ["", ""], "Belt A failed to transfer item out.")
	assert(belt_b.items == ["", "copper_ore"], "Belt B failed to receive and shift item from Belt A.")