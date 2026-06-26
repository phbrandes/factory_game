extends Node

## Debug version to understand splitter round-robin

const BeltSegmentRef = preload("res://src/core/belt_segment.gd")
const SplitterEntityRef = preload("res://src/core/splitter_entity.gd")

func _ready() -> void:
	run_tests()
	get_tree().quit()

func run_tests() -> void:
	print("=== SPLITTER DEBUG TEST ===")
	_debug_round_robin()

func _debug_round_robin() -> void:
	var splitter = SplitterEntityRef.new("splitter")
	var belt_a = BeltSegmentRef.new("belt_a", 1)
	var belt_b = BeltSegmentRef.new("belt_b", 1)
	
	splitter.add_output(belt_a)
	splitter.add_output(belt_b)
	
	print("Outputs: %d" % splitter.outputs.size())
	
	# Push Item 1
	print("\n--- Item 1 (iron) ---")
	print("Before receive: splitter._current_output_index = %d" % splitter._current_output_index)
	splitter.receive_item("iron")
	splitter.tick()
	print("After tick: splitter._current_output_index = %d" % splitter._current_output_index)
	print("  belt_a.items = %s" % [belt_a.items])
	print("  belt_b.items = %s" % [belt_b.items])
	belt_a.tick() # Try to clear
	print("After belt_a.tick(): belt_a.items = %s" % [belt_a.items])
	
	# Push Item 2
	print("\n--- Item 2 (copper) ---")
	print("Before receive: splitter._current_output_index = %d" % splitter._current_output_index)
	splitter.receive_item("copper")
	splitter.tick()
	print("After tick: splitter._current_output_index = %d" % splitter._current_output_index)
	print("  belt_a.items = %s" % [belt_a.items])
	print("  belt_b.items = %s" % [belt_b.items])
	belt_b.tick() # Clear
	print("After belt_b.tick(): belt_b.items = %s" % [belt_b.items])
	
	# Push Item 3
	print("\n--- Item 3 (coal) ---")
	print("Before receive: splitter._current_output_index = %d" % splitter._current_output_index)
	splitter.receive_item("coal")
	splitter.tick()
	print("After tick: splitter._current_output_index = %d" % splitter._current_output_index)
	print("  belt_a.items = %s (expected: ['coal'])" % [belt_a.items])
	print("  belt_b.items = %s" % [belt_b.items])
	
	if belt_a.items[0] == "coal":
		print("\n✓ PASS: Round-robin works")
	else:
		print("\n✗ FAIL: Item 3 did not go to belt_a")
