extends Node

## Standalone test runner for SplitterEntity logic.

const BeltSegmentRef = preload("res://src/core/belt_segment.gd")
const SplitterEntityRef = preload("res://src/core/splitter_entity.gd")

func run_tests() -> void:
	print("Running SplitterEntity Tests...")
	
	_test_round_robin_split()
	_test_splitter_backpressure()
	_test_merger_functionality()
	
	print("All SplitterEntity tests passed.")

func _test_round_robin_split() -> void:
	var splitter = SplitterEntityRef.new("splitter")
	var belt_a = BeltSegmentRef.new("belt_a", 1)
	var belt_b = BeltSegmentRef.new("belt_b", 1)
	
	splitter.add_output(belt_a)
	splitter.add_output(belt_b)
	
	# Push Item 1
	assert(splitter.receive_item("iron"), "Splitter rejected first item.")
	splitter.tick()
	assert(belt_a.items[0] == "iron", "First item did not go to Output A.")
	assert(belt_b.items[0] == "", "Item duplicated to Output B.")
	belt_a.tick() # Clear belt A
	
	# Push Item 2
	assert(splitter.receive_item("copper"), "Splitter rejected second item.")
	splitter.tick()
	assert(belt_b.items[0] == "copper", "Second item did not go to Output B.")
	belt_b.tick() # Clear belt B
	
	# Push Item 3 (Should wrap back to A)
	assert(splitter.receive_item("coal"), "Splitter rejected third item.")
	splitter.tick()
	assert(belt_a.items[0] == "coal", "Third item did not wrap back to Output A.")

func _test_splitter_backpressure() -> void:
	var splitter = SplitterEntityRef.new("splitter")
	var belt_a = BeltSegmentRef.new("belt_a", 1)
	var belt_b = BeltSegmentRef.new("belt_b", 1)
	
	splitter.add_output(belt_a)
	splitter.add_output(belt_b)
	
	# Force Output A to be full
	belt_a.receive_item("junk")
	
	# Push Item. Normally it wants to go to A first.
	splitter.receive_item("iron")
	splitter.tick()
	
	# Since A is full, it should automatically route to B
	assert(belt_b.items[0] == "iron", "Splitter failed to route around full output.")
	
	# Force Output B to be full as well
	belt_b.receive_item("junk_2")
	
	# Push another item into the splitter buffer
	assert(splitter.receive_item("stuck_item"), "Splitter buffer failed to accept item.")
	
	# Tick the splitter. Both outputs are full.
	splitter.tick()
	
	# The item should remain stuck inside the splitter
	assert(splitter._internal_buffer == "stuck_item", "Splitter lost item when all outputs were blocked!")
	assert(splitter.can_accept_item() == false, "Splitter accepted item while its internal buffer was full!")

func _test_merger_functionality() -> void:
	var splitter = SplitterEntityRef.new("merger")
	var out_belt = BeltSegmentRef.new("out_belt", 2)
	
	var in_belt_1 = BeltSegmentRef.new("in_1", 1)
	var in_belt_2 = BeltSegmentRef.new("in_2", 1)
	
	splitter.add_output(out_belt)
	in_belt_1.output_target = splitter
	in_belt_2.output_target = splitter
	
	# Load both input belts
	in_belt_1.receive_item("A")
	in_belt_2.receive_item("B")
	
	# Tick 1: Belt 1 pushes to splitter buffer. Belt 2 cannot (buffer is full). Splitter pushes buffer to out_belt.
	in_belt_1.tick()
	in_belt_2.tick()
	splitter.tick()
	
	# Tick 2: Out belt shifts. Belt 2 pushes to splitter buffer. Splitter pushes to out_belt.
	out_belt.tick()
	in_belt_1.tick()
	in_belt_2.tick()
	splitter.tick()
	
	# Verify both items made it to the output belt
	assert(out_belt.items.has("A"), "Item A failed to merge.")
	assert(out_belt.items.has("B"), "Item B failed to merge.")
	assert(out_belt.items == ["B", "A"] or out_belt.items == ["A", "B"], "Merge result incorrect.")