extends Node

## Standalone test runner for ExtractorEntity bridging logic.

const GridManagerRef = preload("res://src/core/grid_manager.gd")
const BeltSegmentRef = preload("res://src/core/belt_segment.gd")
const StorageEntityRef = preload("res://src/core/storage_entity.gd")
const ExtractorEntityRef = preload("res://src/core/extractor_entity.gd")
const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")
const ProductionEntityRef = preload("res://src/core/production_entity.gd")

func run_tests() -> void:
	print("Running ExtractorEntity Tests...")
	
	_test_successful_transfer()
	_test_starvation_and_backpressure()
	_test_furnace_extraction()
	
	print("All ExtractorEntity tests passed.")

func _test_successful_transfer() -> void:
	var grid = GridManagerRef.new()
	var storage = StorageEntityRef.new("chest", 10)
	var belt = BeltSegmentRef.new("belt", 1)
	
	# Extractor takes 2 ticks per swing (2 to target, 2 to return)
	var extractor = ExtractorEntityRef.new("inserter", grid, Vector2i(0, 0), Vector2i(2, 0), 2)
	
	grid.place_entity(storage, Vector2i(0, 0))
	grid.place_entity(extractor, Vector2i(1, 0))
	grid.place_entity(belt, Vector2i(2, 0))
	
	# Load storage
	storage.receive_item("iron_plate")
	
	assert(extractor.current_state == extractor.State.WAITING_FOR_SOURCE, "Initial state incorrect.")
	
	# Tick 1: Grabs item, starts swinging
	extractor.tick()
	assert(extractor.held_item == "iron_plate", "Failed to grab item.")
	assert(storage.inventory.total_items == 0, "Source inventory not depleted.")
	assert(extractor.current_state == extractor.State.SWINGING_TO_TARGET, "Failed state transition.")
	
	# Tick 2: Arrives at target and drops immediately
	extractor.tick()
	assert(extractor.held_item == "", "Failed to drop item.")
	assert(belt.items[0] == "iron_plate", "Target did not receive item.")
	assert(extractor.current_state == extractor.State.SWINGING_TO_SOURCE, "Failed to begin return swing.")
	
	# Tick 3: Returns to source
	extractor.tick()
	assert(extractor.current_state == extractor.State.WAITING_FOR_SOURCE, "Failed to reset to waiting state.")

func _test_starvation_and_backpressure() -> void:
	var grid = GridManagerRef.new()
	var source_storage = StorageEntityRef.new("chest_in", 1)
	var target_storage = StorageEntityRef.new("chest_out", 1)
	var extractor = ExtractorEntityRef.new("inserter", grid, Vector2i(0, 0), Vector2i(2, 0), 1)
	
	grid.place_entity(source_storage, Vector2i(0, 0))
	grid.place_entity(target_storage, Vector2i(2, 0))
	
	# Starvation Test
	extractor.tick()
	assert(extractor.current_state == extractor.State.WAITING_FOR_SOURCE, "Extractor moved without source item.")
	
	# Provide item
	source_storage.receive_item("coal")
	
	# Backpressure Test: Fill target storage
	target_storage.receive_item("blocker")
	
	# Tick 1: Grab and swing (1 tick swing means it arrives and tries to drop)
	extractor.tick()
	
	assert(extractor.held_item == "coal", "Lost item during transit.")
	assert(extractor.current_state == extractor.State.WAITING_FOR_TARGET, "Extractor dropped item into full storage!")
	
	# Clear target storage
	target_storage.extract_item("blocker", 1)
	
	# Tick 2: Drop succeeds, swings back
	extractor.tick()
	assert(target_storage.inventory.contents.has("coal"), "Failed to drop after target cleared.")
	assert(extractor.current_state == extractor.State.WAITING_FOR_SOURCE, "Failed to return.")

func _test_furnace_extraction() -> void:
	var grid = GridManagerRef.new()
	var furnace = ProductionEntityRef.new("furnace", 10, 10)
	var recipe = RecipeResourceRef.new("smelt", {"ore": 1}, {"plate": 1}, 1)
	furnace.set_recipe(recipe)
	var storage = StorageEntityRef.new("chest", 10)
	
	var extractor = ExtractorEntityRef.new("inserter", grid, Vector2i(0, 0), Vector2i(2, 0), 1)
	
	grid.place_entity(furnace, Vector2i(0, 0))
	grid.place_entity(storage, Vector2i(2, 0))
	
	# Force an item into the furnace output
	furnace.output_inventory.add_item("plate", 1)
	
	# Grab
	extractor.tick()
	assert(extractor.held_item == "plate", "Failed to extract from furnace.")
	assert(furnace.output_inventory.total_items == 0, "Furnace output not depleted.")