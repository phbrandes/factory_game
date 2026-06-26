extends Node

## Debug version to understand the belt transfer issue

const BeltSegmentRef = preload("res://src/core/belt_segment.gd")

func _ready() -> void:
	run_tests()
	get_tree().quit()

func run_tests() -> void:
	print("=== BELT DEBUG TEST ===")
	_debug_cross_segment_transfer()

func _debug_cross_segment_transfer() -> void:
	var belt_a = BeltSegmentRef.new("belt_a", 2)
	var belt_b = BeltSegmentRef.new("belt_b", 2)
	
	# Link A to B
	belt_a.output_target = belt_b
	
	belt_a.receive_item("copper_ore")
	print("After receive: belt_a.items = %s, belt_b.items = %s" % [belt_a.items, belt_b.items])
	
	# Tick 1: Ore moves to A[1]
	belt_a.tick()
	belt_b.tick()
	print("After Tick 1:")
	print("  belt_a.items = %s (expected: ['', 'copper_ore'])" % [belt_a.items])
	print("  belt_b.items = %s (expected: ['', ''])" % [belt_b.items])
	
	# Tick 2: Ore transfers to B[0]
	print("\nBefore Tick 2:")
	print("  belt_a.items[1] = '%s'" % belt_a.items[1])
	print("  belt_b.can_accept_item() = %s" % belt_b.can_accept_item())
	print("  belt_b.items[0] = '%s'" % belt_b.items[0])
	
	belt_a.tick()
	print("After belt_a.tick():")
	print("  belt_a.items = %s" % [belt_a.items])
	print("  belt_b.items = %s" % [belt_b.items])
	
	belt_b.tick()
	print("After belt_b.tick():")
	print("  belt_a.items = %s" % [belt_a.items])
	print("  belt_b.items = %s (expected: ['copper_ore', ''])" % [belt_b.items])
	
	if belt_b.items == ["copper_ore", ""]:
		print("\n✓ PASS: Transfer successful")
	else:
		print("\n✗ FAIL: Transfer failed. Got %s, expected ['copper_ore', '']" % [belt_b.items])
