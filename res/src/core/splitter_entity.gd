class_name SplitterEntity
extends GridEntity

## Pure data representation of a Splitter/Merger.
## Accepts items and distributes them round-robin to connected outputs.

var outputs: Array[Object] = []
var _current_output_index: int = 0
var _internal_buffer: String = ""

func _init(p_id: String, size: Vector2i = Vector2i.ONE) -> void:
	super._init(p_id, size)

## Adds an output target to the splitter's routing list.
func add_output(target: Object) -> void:
	if not outputs.has(target):
		outputs.append(target)

## TWO-PHASE LOGISTICS: Phase 1 (Check)
## A splitter can accept an item if its internal buffer is empty.
func can_accept_item() -> bool:
	return _internal_buffer == ""

## TWO-PHASE LOGISTICS: Phase 2 (Execute)
func receive_item(item_id: String) -> bool:
	if can_accept_item():
		_internal_buffer = item_id
		return true
	return false

## Called by TickScheduler. Attempts to push the buffered item to an output.
func tick() -> void:
	if _internal_buffer != "":
		_process_split()

func _process_split() -> void:
	var output_count = outputs.size()
	if output_count == 0:
		return
		
	# Try outputs starting from the current round-robin index
	for i in range(output_count):
		var check_index = (_current_output_index + i) % output_count
		var target = outputs[check_index]
		
		if target != null and target.has_method("can_accept_item") and target.has_method("receive_item"):
			if target.can_accept_item():
				# Transfer successful
				target.receive_item(_internal_buffer)
				_internal_buffer = ""
				# Advance the round-robin index for the NEXT item
				_current_output_index = (check_index + 1) % output_count
				return