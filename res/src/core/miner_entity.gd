extends GridEntity

## Pure data representation of an extraction machine.
## Uses a null-input recipe to continuously generate output.

var output_inventory: InventoryComponent
var crafter: CraftingComponent
var _dummy_input_inv: InventoryComponent # Required for the CraftingComponent constructor, but never used.

func _init(p_id: String, output_capacity: int, p_size: Vector2i = Vector2i.ONE) -> void:
	super._init(p_id, p_size)
	output_inventory = InventoryComponent.new(output_capacity)
	_dummy_input_inv = InventoryComponent.new(0)
	crafter = CraftingComponent.new(_dummy_input_inv, output_inventory)

## Assigns the mining recipe (should have empty inputs).
func set_mining_resource(resource_recipe: RecipeResource) -> void:
	crafter.set_recipe(resource_recipe)

## Miners generally do not accept items from logistics networks.
func can_accept_item() -> bool:
	return false

func receive_item(_item_id: String) -> bool:
	return false

## TWO-PHASE LOGISTICS (Output): Helper for extractors/belts pulling from this machine
func can_provide_item(item_id: String, amount: int = 1) -> bool:
	return output_inventory.contents.get(item_id, 0) >= amount

func extract_item(item_id: String, amount: int = 1) -> bool:
	return output_inventory.remove_item(item_id, amount)

## Advances the mining simulation.
func tick() -> void:
	crafter.tick()