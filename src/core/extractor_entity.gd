class_name ExtractorEntity
extends GridEntity

## Pure data representation of an Inserter/Robotic Arm.
## Moves items from a source coordinate to a target coordinate deterministically.

enum State {
	WAITING_FOR_SOURCE, # Waiting for an item to appear at the source
	SWINGING_TO_TARGET, # Item grabbed, moving towards target
	WAITING_FOR_TARGET, # At target, waiting for space to open up
	SWINGING_TO_SOURCE  # Item dropped, returning to starting position
}

var source_pos: Vector2i
var target_pos: Vector2i
var grid: GridManager # Reference needed to query dynamic source/target entities

var current_state: State = State.WAITING_FOR_SOURCE
var ticks_per_swing: int = 5
var progress_ticks: int = 0
var held_item: String = ""

func _init(p_id: String, p_grid: GridManager, p_source: Vector2i, p_target: Vector2i, p_speed: int = 5) -> void:
	super._init(p_id, Vector2i.ONE)
	grid = p_grid
	source_pos = p_source
	target_pos = p_target
	ticks_per_swing = p_speed

## Called by TickScheduler.
func tick() -> void:
	match current_state:
		State.WAITING_FOR_SOURCE:
			_try_grab()
		State.SWINGING_TO_TARGET:
			_process_swing(State.WAITING_FOR_TARGET)
		State.WAITING_FOR_TARGET:
			_try_drop()
		State.SWINGING_TO_SOURCE:
			_process_swing(State.WAITING_FOR_SOURCE)

func _try_grab() -> void:
	var source_entity = grid.get_entity_at(source_pos)
	if source_entity == null or not source_entity.has_method("can_provide_item") or not source_entity.has_method("extract_item"):
		return
		
	# For Phase 3, we just grab the first available item if we are generic.
	# A filter-inserter would check for specific items here.
	var available_items = []
	
	# Check for output_inventory (ProductionEntity)
	if source_entity.get("output_inventory") != null:
		available_items = source_entity.output_inventory.contents.keys()
	# Check for inventory (StorageEntity)
	elif source_entity.get("inventory") != null:
		available_items = source_entity.inventory.contents.keys()
	# Check for belt items
	elif source_entity is BeltSegment and source_entity.items[0] != "":
		available_items = [source_entity.items[0]]

	for item_id in available_items:
		if source_entity.can_provide_item(item_id, 1):
			if source_entity.extract_item(item_id, 1):
				held_item = item_id
				current_state = State.SWINGING_TO_TARGET
				progress_ticks = 0
				return

func _try_drop() -> void:
	var target_entity = grid.get_entity_at(target_pos)
	if target_entity == null or not target_entity.has_method("can_accept_item") or not target_entity.has_method("receive_item"):
		return
		
	if target_entity.can_accept_item():
		if target_entity.receive_item(held_item):
			held_item = ""
			current_state = State.SWINGING_TO_SOURCE
			progress_ticks = 0

func _process_swing(next_state: State) -> void:
	progress_ticks += 1
	if progress_ticks >= ticks_per_swing:
		current_state = next_state
		
		# Immediately attempt the next action so we don't waste a tick waiting
		if next_state == State.WAITING_FOR_TARGET:
			_try_drop()
		elif next_state == State.WAITING_FOR_SOURCE:
			_try_grab()