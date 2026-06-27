class_name InventoryComponent
extends RefCounted

## Pure data component managing a collection of item stacks across slots.

var slot_count: int = 0
var slots: Array[Dictionary] = [] # Array of {"item_id": String, "count": int, "max_stack": int}



# Aggregated totals for O(1) lookups (Maintains API compatibility with older systems)
var contents: Dictionary = {}
var total_items: int = 0

func _init(p_slot_count: int) -> void:
	slot_count = p_slot_count
	for i in range(slot_count):
		slots.append({"item_id": "", "count": 0, "max_stack": 0})

## Checks if there is at least one completely empty slot.
func has_space() -> bool:
	for slot in slots:
		if slot.item_id == "":
			return true
	return false

## Checks if the inventory can fit a specific amount of a specific item.
func has_space_for(item_id: String, amount: int, max_stack: int = 50) -> bool:
	var remaining = amount
	for slot in slots:
		if slot.item_id == item_id:
			remaining -= (slot.max_stack - slot.count)
		elif slot.item_id == "":
			remaining -= max_stack
			
		if remaining <= 0:
			return true
	return false

## Checks if multiple items can fit simultaneously (Used heavily by CraftingComponent).
func has_space_for_multiple(items: Dictionary, max_stack: int = 50) -> bool:
	# Simulate adding all items to a copy of the slots to ensure transactional integrity
	var simulated_slots = []
	for s in slots:
		simulated_slots.append(s.duplicate())
		
	for item_id in items:
		var remaining = items[item_id]
		
		# Pass 1: existing incomplete stacks
		for slot in simulated_slots:
			if slot.item_id == item_id and slot.count < slot.max_stack:
				var available = slot.max_stack - slot.count
				var to_add = mini(available, remaining)
				slot.count += to_add
				remaining -= to_add
				
		# Pass 2: empty slots
		if remaining > 0:
			for slot in simulated_slots:
				if slot.item_id == "":
					slot.item_id = item_id
					slot.max_stack = max_stack
					var to_add = mini(max_stack, remaining)
					slot.count += to_add
					remaining -= to_add
					if remaining <= 0:
						break
		
		if remaining > 0:
			return false # Failed to fit this specific item
			
	return true

## Adds an item, automatically stacking it. Returns true if fully successful.
func add_item(item_id: String, amount: int = 1, max_stack: int = 50) -> bool:
	if not has_space_for(item_id, amount, max_stack):
		return false
		
	var remaining = amount
	
	# Pass 1: Add to existing incomplete stacks
	for slot in slots:
		if slot.item_id == item_id and slot.count < slot.max_stack:
			var available = slot.max_stack - slot.count
			var to_add = mini(available, remaining)
			slot.count += to_add
			remaining -= to_add
			if remaining == 0:
				break
				
	# Pass 2: Fill empty slots
	if remaining > 0:
		for slot in slots:
			if slot.item_id == "":
				slot.item_id = item_id
				slot.max_stack = max_stack
				var to_add = mini(max_stack, remaining)
				slot.count += to_add
				remaining -= to_add
				if remaining == 0:
					break
					
	_recalculate_totals()
	return true

## Removes an item from stacks. Returns true if fully successful.
func remove_item(item_id: String, amount: int = 1) -> bool:
	if contents.get(item_id, 0) < amount:
		return false
		
	var remaining = amount
	# Iterate backwards to empty latest slots first (LIFO stacking behavior)
	for i in range(slots.size() - 1, -1, -1):
		var slot = slots[i]
		if slot.item_id == item_id:
			var to_remove = mini(slot.count, remaining)
			slot.count -= to_remove
			remaining -= to_remove
			
			if slot.count == 0:
				slot.item_id = ""
				slot.max_stack = 0
				
			if remaining == 0:
				break
				
	_recalculate_totals()
	return true

## Clears all slots.
func clear() -> void:
	for slot in slots:
		slot.item_id = ""
		slot.count = 0
		slot.max_stack = 0
	_recalculate_totals()

func _recalculate_totals() -> void:
	contents.clear()
	total_items = 0
	for slot in slots:
		if slot.item_id != "":
			if contents.has(slot.item_id):
				contents[slot.item_id] += slot.count
			else:
				contents[slot.item_id] = slot.count
			total_items += slot.count