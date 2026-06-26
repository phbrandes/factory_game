extends GridEntity

## Pure data representation of a storage container (e.g., a chest or silo).
## Acts as a terminus for conveyor networks.

var inventory: InventoryComponent

func _init(p_id: String, capacity: int, p_size: Vector2i = Vector2i.ONE) -> void:
	super._init(p_id, p_size)
	inventory = InventoryComponent.new(capacity)

## TWO-PHASE LOGISTICS: Phase 1 (Check)
func can_accept_item() -> bool:
	return inventory.has_space()

## TWO-PHASE LOGISTICS: Phase 2 (Execute)
func receive_item(item_id: String) -> bool:
	return inventory.add_item(item_id, 1)

## Optional helper for production/consumption chains later
func can_provide_item(item_id: String, amount: int = 1) -> bool:
	return inventory.contents.get(item_id, 0) >= amount

func extract_item(item_id: String, amount: int = 1) -> bool:
	return inventory.remove_item(item_id, amount)