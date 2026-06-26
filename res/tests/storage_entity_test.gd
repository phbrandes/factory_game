extends Node

## Standalone test runner for StorageEntity and InventoryComponent logic.

const BeltSegmentRef = preload("res://src/core/belt_segment.gd")
const StorageEntityRef = preload("res://src/core/storage_entity.gd")

func run_tests() -> void:
	print("Running StorageEntity Tests...")
	
	_test_inventory_limits()
	_test_belt_to_storage_transfer()
	
	print("All StorageEntity tests passed.")

func _test_inventory_limits() -> void:
	var storage = StorageEntityRef.new("chest_t1", 2) # Capacity of 2
	
	assert(storage.can_accept_item() == true, "Empty storage should accept items.")
	assert(storage.receive_item("iron_ore") == true, "Failed to receive first item.")
	assert(storage.receive_item("copper_ore") == true, "Failed to receive second item.")
	
	assert(storage.can_accept_item() == false, "Full storage should reject items.")
	assert(storage.receive_item("coal") == false, "Storage accepted item beyond capacity!")
	
	assert(storage.inventory.total_items == 2, "Inventory count mismatch.")
	assert(storage.inventory.contents["iron_ore"] == 1, "Item tracking error.")

func _test_belt_to_storage_transfer() -> void:
	var belt = BeltSegmentRef.new("belt", 1)
	var storage = StorageEntityRef.new("chest", 1)
	
	# Connect belt output to storage
	belt.output_target = storage
	
	belt.receive_item("iron_plate")
	assert(belt.items[0] == "iron_plate", "Belt setup failed.")
	
	# Tick 1: Belt pushes to storage
	belt.tick()
	
	assert(belt.items[0] == "", "Belt failed to clear item after transfer.")
	assert(storage.inventory.contents.has("iron_plate"), "Storage failed to receive item from belt.")
	assert(storage.inventory.total_items == 1, "Storage count incorrect after transfer.")
	
	# Test Backpressure: Storage is full, belt should hold next item
	belt.receive_item("copper_plate")
	belt.tick()
	
	assert(belt.items[0] == "copper_plate", "Belt transferred item into full storage!")
	assert(storage.inventory.total_items == 1, "Storage overfilled via belt transfer!")