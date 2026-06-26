extends GridEntity

## Pure data representation of a production machine with optional power consumption.

var input_inventory: InventoryComponent
var output_inventory: InventoryComponent
var crafter: CraftingComponent
var power_consumer: PowerConsumerComponent # Optional: Can be null

func _init(p_id: String, input_capacity: int, output_capacity: int, p_size: Vector2i = Vector2i.ONE, p_power_consumer: PowerConsumerComponent = null) -> void:
	super._init(p_id, p_size)
	input_inventory = InventoryComponent.new(input_capacity)
	output_inventory = InventoryComponent.new(output_capacity)
	crafter = CraftingComponent.new(input_inventory, output_inventory)
	power_consumer = p_power_consumer

func set_recipe(recipe: RecipeResource) -> void:
	crafter.set_recipe(recipe)

## TWO-PHASE LOGISTICS (Input)
func can_accept_item() -> bool:
	return input_inventory.has_space()

func receive_item(item_id: String) -> bool:
	return input_inventory.add_item(item_id, 1)

## TWO-PHASE LOGISTICS (Output)
func can_provide_item(item_id: String, amount: int = 1) -> bool:
	return output_inventory.contents.get(item_id, 0) >= amount

func extract_item(item_id: String, amount: int = 1) -> bool:
	return output_inventory.remove_item(item_id, amount)

## Advances the crafting simulation only if power requirements are met.
func tick() -> void:
	# If this machine requires power, try to consume it. 
	# If it fails, we simply skip the tick entirely, stalling the craft.
	if power_consumer != null:
		if not power_consumer.try_consume():
			return # Brownout: Machine stalls until next tick
			
	crafter.tick()