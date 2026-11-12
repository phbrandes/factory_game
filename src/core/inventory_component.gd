class_name Inventory_Component
extends RefCounted

## Pure data component managing items with slot-based capacity and stack limits.

var capacity: int = 0
var max_stack_size: int = 50
var contents: Dictionary = {} # Maps item_id (String) to quantity (int)

func _init(p_capacity: int, p_max_stack_size: int = 50) -> void:
	capacity = p_capacity
	max_stack_size = p_max_stack_size

## Checks if there is space for the given amount of a specific item.
func has_space_for(item_id: String, amount: int = 1) -> bool:
	# If we have the item, check if adding to the existing stack exceeds limit
	if contents.has(item_id):
		return (contents[item_id] + amount) <= max_stack_size
	
	# If new item, check if we have an empty slot
	return contents.size() < capacity

## Adds an item. Returns true if successful, false if no space/limit reached.
func add_item(item_id: String, amount: int = 1) -> bool:
	if not has_space_for(item_id, amount):
		return false
		
	contents[item_id] = contents.get(item_id, 0) + amount
	return true

## Removes an item. Returns true if successful, false if not enough.
func remove_item(item_id: String, amount: int = 1) -> bool:
	if not contents.has(item_id) or contents[item_id] < amount:
		return false
		
	contents[item_id] -= amount
	
	if contents[item_id] <= 0:
		contents.erase(item_id)
		
	return true

## Clears the inventory.
func clear() -> void:
	contents.clear()

## Helper to get current count of a specific item
func get_count(item_id: String) -> int:
	return contents.get(item_id, 0)
