class_name BeltSegment
extends GridEntity

## Pure data representation of a linear conveyor belt segment.
## Shifts items forward along an internal array and pushes them to an output target.

var length: int
var items: Array[String]
var output_target: Object # WeakRef or direct reference to the next grid entity
var facing_direction: Vector2i = Vector2i(1, 0) # Default to EAST

func _init(p_id: String, p_length: int = 1, p_facing: Vector2i = Vector2i(1, 0)) -> void:
	super._init(p_id, Vector2i(p_length, 1)) # Size represents footprint. 
	length = p_length
	facing_direction = p_facing
	items = []
	items.resize(length)
	items.fill("") # "" represents an empty physical slot on the belt

## TWO-PHASE LOGISTICS: Phase 1 (Check)
## Returns true if the very first slot on the belt is empty.
func can_accept_item() -> bool:
	return items[0] == ""

## TWO-PHASE LOGISTICS: Phase 2 (Execute)
## Places an item onto the start of the belt. Fails if occupied.
func receive_item(item_id: String) -> bool:
	if can_accept_item():
		items[0] = item_id
		return true
	return false

## Called by the TickScheduler or a controlling LogisticsManager
func tick() -> void:
	_process_output()
	_process_shift()

## Attempts to push the item at the end of the belt to the connected output target
func _process_output() -> void:
	if items[length - 1] != "":
		if output_target != null and output_target.has_method("can_accept_item") and output_target.has_method("receive_item"):
			if output_target.can_accept_item():
				output_target.receive_item(items[length - 1])
				items[length - 1] = ""

## Shifts all items forward by one slot, iterating backwards to prevent overwrites.
func _process_shift() -> void:
	for i in range(length - 2, -1, -1):
		# If current slot has an item AND the slot ahead is empty
		if items[i] != "" and items[i + 1] == "":
			items[i + 1] = items[i]
			items[i] = ""