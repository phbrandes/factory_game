extends GridEntity

## A laboratory machine that consumes items to advance the ProgressionManager.

var progression: ProgressionManager
var input_inventory: InventoryComponent
var power_consumer: PowerConsumerComponent # Optional

func _init(p_id: String, p_progression: ProgressionManager, capacity: int = 10, p_size: Vector2i = Vector2i.ONE, p_power: PowerConsumerComponent = null) -> void:
	super._init(p_id, p_size)
	progression = p_progression
	input_inventory = InventoryComponent.new(capacity)
	power_consumer = p_power

## TWO-PHASE LOGISTICS (Check): Only accepts items if there's space AND the research needs it.
func can_accept_item(item_id: String = "") -> bool:
	if not input_inventory.has_space():
		return false
	# If specific item is polled, ensure the progression system actually needs it right now.
	if item_id != "" and not progression.needs_item(item_id):
		return false
	# If no specific item polled, just check if we have space (standard fallback)
	return true

## TWO-PHASE LOGISTICS (Execute)
func receive_item(item_id: String) -> bool:
	if can_accept_item(item_id):
		return input_inventory.add_item(item_id, 1)
	return false

## Processes items in the inventory into research progress.
func tick() -> void:
	if power_consumer != null and not power_consumer.try_consume():
		return # Brownout
		
	if progression.active_research == null:
		return # Nothing to research
		
	# Consume up to 1 item per tick for research
	for item_id in input_inventory.contents.keys():
		if progression.needs_item(item_id):
			if input_inventory.remove_item(item_id, 1):
				progression.add_progress(item_id, 1)
				return # Only process 1 science pack per tick to simulate time