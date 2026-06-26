class_name InventoryComponent
extends RefCounted

## Pure data component managing a collection of items and their quantities.

var capacity: int = 0
var contents: Dictionary = {} # Maps item_id (String) to quantity (int)
var total_items: int = 0

func _init(p_capacity: int) -> void:
	capacity = p_capacity

## Checks if there is space for at least one more item.
func has_space() -> bool:
	return total_items < capacity

## Checks if there is space for a specific amount.
func has_space_for(amount: int) -> bool:
	return total_items + amount <= capacity

## Adds an item. Returns true if successful, false if full.
func add_item(item_id: String, amount: int = 1) -> bool:
	if not has_space_for(amount):
		return false
		
	if contents.has(item_id):
		contents[item_id] += amount
	else:
		contents[item_id] = amount
		
	total_items += amount
	return true

## Removes an item. Returns true if successful, false if not enough.
func remove_item(item_id: String, amount: int = 1) -> bool:
	if not contents.has(item_id) or contents[item_id] < amount:
		return false
		
	contents[item_id] -= amount
	total_items -= amount
	
	if contents[item_id] == 0:
		contents.erase(item_id)
		
	return true

## Clears the inventory.
func clear() -> void:
	contents.clear()
	total_items = 0