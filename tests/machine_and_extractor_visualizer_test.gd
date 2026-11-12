extends Node

## Standalone test runner verifying orthogonal BeltVisualizer, MachineVisualizer, ExtractorVisualizer,
## CombatVisualizer, and FactoryRenderer auto-spawning.

const GridManagerRef = preload("res://src/core/grid_manager.gd")
const BeltSegmentRef = preload("res://src/core/belt_segment.gd")
const ProductionEntityRef = preload("res://src/core/production_entity.gd")
const ExtractorEntityRef = preload("res://src/core/extractor_entity.gd")
const EnemyEntityRef = preload("res://src/core/combat/enemy_entity.gd")
const RecipeResourceRef = preload("res://src/core/resources/recipe_resource.gd")
const GridDirectionRef = preload("res://src/core/grid_direction.gd")

const FactoryRendererRef = preload("res://src/visuals/factory_renderer.gd")
const BeltVisualizerRef = preload("res://src/visuals/belt_visualizer.gd")
const MachineVisualizerRef = preload("res://src/visuals/machine_visualizer.gd")
const ExtractorVisualizerRef = preload("res://src/visuals/extractor_visualizer.gd")
const CombatVisualizerRef = preload("res://src/visuals/combat_visualizer.gd")

func run_tests() -> void:
	print("Running Machine, Extractor, and Orthogonal Visualizer Tests...")
	
	_test_orthogonal_belt_visualizer()
	_test_machine_visualizer_states()
	_test_extractor_swing_interpolation()
	_test_factory_renderer_auto_visuals()
	
	print("All Machine, Extractor, and Orthogonal Visualizer tests passed.")

func _test_orthogonal_belt_visualizer() -> void:
	var belt_data := BeltSegmentRef.new("belt_t1", 2)
	var visualizer := BeltVisualizerRef.new()
	add_child(visualizer)
	
	visualizer.setup_orthogonal(belt_data, GridDirectionRef.EAST, 64.0, 1)
	
	assert(visualizer._get_local_pixel_pos_for_index(0) == Vector2.ZERO, "Orthogonal index 0 should be (0, 0).")
	assert(visualizer._get_local_pixel_pos_for_index(1) == Vector2(64, 0), "Orthogonal EAST index 1 should be (64, 0).")
	assert(visualizer.track_sprites.size() == 2, "BeltVisualizer should create 2 animated track sprites.")
	
	belt_data.receive_item("iron_ore")
	visualizer.on_simulation_tick()
	
	var item_sprite: Sprite2D = visualizer.item_sprites[0]
	assert(item_sprite.visible == true, "Item sprite should be visible.")
	assert(item_sprite.texture != null, "Item sprite should have iron_ore AtlasTexture assigned.")
	
	visualizer.queue_free()

func _test_machine_visualizer_states() -> void:
	var machine := ProductionEntityRef.new("assembler_t1", 10, 2)
	var recipe := RecipeResourceRef.new("smelt_iron", {"iron_ore": 1}, {"iron_plate": 1}, 5)
	machine.set_recipe(recipe)
	
	var vis := MachineVisualizerRef.new()
	add_child(vis)
	vis.setup(machine, 64.0)
	
	# 1. Initially IDLE
	assert(vis.current_state == MachineVisualizerRef.VisualState.IDLE, "Machine should start IDLE.")
	assert(vis.machine_sprite.animation == "idle", "Machine sprite should play idle animation.")
	
	# 2. Feed input and tick once -> WORKING
	machine.receive_item("iron_ore")
	machine.tick()
	vis.on_simulation_tick()
	assert(vis.current_state == MachineVisualizerRef.VisualState.WORKING, "Machine should enter WORKING state while crafting.")
	assert(vis.machine_sprite.animation == "working", "Machine sprite should play working animation.")
	
	# 3. Fill output inventory to capacity (2) -> OUTPUT_FULL
	machine.output_inventory.add_item("iron_plate", 2)
	vis.on_simulation_tick()
	assert(vis.current_state == MachineVisualizerRef.VisualState.OUTPUT_FULL, "Machine should report OUTPUT_FULL when output is full.")
	
	vis.queue_free()

func _test_extractor_swing_interpolation() -> void:
	var grid := GridManagerRef.new()
	var extractor := ExtractorEntityRef.new("extractor_t1", grid, Vector2i(0, 0), Vector2i(2, 0), 4)
	extractor.grid_position = Vector2i(1, 0)
	
	var vis := ExtractorVisualizerRef.new()
	add_child(vis)
	vis.setup(extractor, 64.0, 1)
	
	# Simulate grabbing an item and advancing 2 of 4 ticks (50% swing)
	extractor.held_item = "copper_ore"
	extractor.current_state = ExtractorEntityRef.State.SWINGING_TO_TARGET
	extractor.progress_ticks = 2
	vis.on_simulation_tick()
	
	# Halfway through the 0.1s tick (0.0 -> 0.5 lerped at 50% = 0.25)
	vis._process(0.05)
	assert(is_equal_approx(vis.visual_swing_ratio, 0.25), "Extractor swing ratio interpolation failed.")
	assert(vis.held_item_sprite.visible == true, "Held item sprite should be visible while carrying copper_ore.")
	assert(vis.held_item_sprite.texture != null, "Held item sprite should have copper_ore texture.")
	
	vis.queue_free()

func _test_factory_renderer_auto_visuals() -> void:
	var grid := GridManagerRef.new()
	var renderer := FactoryRendererRef.new()
	add_child(renderer)
	renderer.setup(grid)
	
	var miner := ProductionEntityRef.new("building_miner_t1", 5, 5)
	var enemy := EnemyEntityRef.new("orc", 50, 0, 5)
	
	grid.place_entity(miner, Vector2i(2, 3))
	grid.place_entity(enemy, Vector2i(4, 5))
	
	assert(renderer.visual_map.has(miner), "FactoryRenderer should auto-spawn MachineVisualizer for unregistered miner.")
	assert(renderer.visual_map[miner] is MachineVisualizerRef, "Miner visual should be a MachineVisualizer.")
	assert(renderer.visual_map[miner].position == Vector2(2, 3) * 64.0, "Miner orthogonal position should be (128, 192).")
	
	assert(renderer.visual_map.has(enemy), "FactoryRenderer should auto-spawn CombatVisualizer for orc.")
	assert(renderer.visual_map[enemy] is CombatVisualizerRef, "Orc visual should be a CombatVisualizer.")
	
	renderer.queue_free()

