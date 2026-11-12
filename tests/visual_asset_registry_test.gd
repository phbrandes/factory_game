extends Node

## Standalone test runner verifying VisualAssetRegistry texture loading and atlas slicing from src/visuals/game_assets.

const VisualAssetRegistryRef = preload("res://src/visuals/visual_asset_registry.gd")
const GridDirectionRef = preload("res://src/core/grid_direction.gd")

func run_tests() -> void:
	print("Running VisualAssetRegistry Tests...")
	
	_test_item_atlas_slicing()
	_test_machine_sprite_frames()
	_test_belt_and_extractor_frames()
	_test_defense_and_enemy_assets()
	_test_terrain_and_ui_assets()
	
	print("All VisualAssetRegistry tests passed.")

func _test_item_atlas_slicing() -> void:
	var iron_ore := VisualAssetRegistryRef.get_item_texture("iron_ore")
	var copper_plate := VisualAssetRegistryRef.get_item_texture("copper_plate")
	var circuit := VisualAssetRegistryRef.get_item_texture("circuit")
	var gold_ore := VisualAssetRegistryRef.get_item_texture("gold_ore")
	
	assert(iron_ore != null, "Failed to load iron_ore texture.")
	assert(iron_ore.get_size() == Vector2(16, 16), "iron_ore AtlasTexture should be 16x16.")
	assert(copper_plate != null and copper_plate.get_size() == Vector2(16, 16), "copper_plate should be 16x16.")
	assert(circuit != null and circuit.get_size() == Vector2(16, 16), "circuit should be 16x16.")
	assert(gold_ore != null and gold_ore.get_size() == Vector2(16, 16), "gold_ore standalone icon should be 16x16.")

func _test_machine_sprite_frames() -> void:
	var miner_frames := VisualAssetRegistryRef.get_machine_frames("building_miner_t1")
	assert(miner_frames.has_animation("idle"), "Miner missing idle animation.")
	assert(miner_frames.has_animation("working"), "Miner missing working animation.")
	assert(miner_frames.get_frame_count("working") == 4, "Miner working strip should have 4 frames.")
	
	var furnace_frames := VisualAssetRegistryRef.get_machine_frames("building_furnace_t1")
	assert(furnace_frames.get_frame_count("working") == 3, "Stone furnace active strip should have 3 frames.")
	
	var assembler_frames := VisualAssetRegistryRef.get_machine_frames("assembler_t2")
	assert(assembler_frames.get_frame_count("working") == 4, "Assembler T2 running strip should have 4 frames.")

func _test_belt_and_extractor_frames() -> void:
	var belt_east := VisualAssetRegistryRef.get_belt_frames(1, GridDirectionRef.EAST)
	var belt_north := VisualAssetRegistryRef.get_belt_frames(2, GridDirectionRef.NORTH)
	assert(belt_east.get_frame_count("move") == 8, "Conveyor belt should have 8 move animation frames.")
	assert(belt_east.get_frame_texture("move", 0).get_size() == Vector2(16, 16), "Belt frame should be 16x16.")
	assert(belt_north.get_frame_count("move") == 8, "Tier 2 north belt should have 8 move frames.")
	
	var arm_frames := VisualAssetRegistryRef.get_extractor_frames(1)
	assert(arm_frames.size() == 8, "Robotic arm sheet should slice into 8 directional frames.")
	assert(arm_frames[0].get_size() == Vector2(48, 48), "Each robotic arm frame should be 48x48.")
	
	# West (PI) -> Frame 0, East (0.0) -> Frame 4
	assert(VisualAssetRegistryRef.get_extractor_frame(PI, 1) == arm_frames[0], "West angle should map to frame 0.")
	assert(VisualAssetRegistryRef.get_extractor_frame(0.0, 1) == arm_frames[4], "East angle should map to frame 4.")

func _test_defense_and_enemy_assets() -> void:
	var turret_tex := VisualAssetRegistryRef.get_turret_texture("turret_gun_t1")
	var wall_tex := VisualAssetRegistryRef.get_turret_texture("defence_wall_t1")
	assert(turret_tex != null and turret_tex.get_size() == Vector2(32, 32), "Turret T1 texture should be 32x32.")
	assert(wall_tex != null and wall_tex.get_size() == Vector2(32, 32), "Defence wall T1 texture should be 32x32.")
	
	var orc_frames := VisualAssetRegistryRef.get_enemy_frames("orc")
	assert(orc_frames.has_animation("idle") and orc_frames.get_frame_count("idle") == 6, "Orc should have 6 idle frames.")
	assert(orc_frames.has_animation("walk") and orc_frames.get_frame_count("walk") == 8, "Orc should have 8 walk frames.")
	assert(orc_frames.has_animation("attack") and orc_frames.get_frame_count("attack") == 6, "Orc should have 6 attack frames.")
	assert(orc_frames.has_animation("death") and orc_frames.get_frame_count("death") == 4, "Orc should have 4 death frames.")
	
	var slime_frames := VisualAssetRegistryRef.get_enemy_frames("slime")
	assert(slime_frames.get_frame_count("walk") > 1, "Slime walk animation failed to slice.")

func _test_terrain_and_ui_assets() -> void:
	var grass := VisualAssetRegistryRef.get_terrain_texture("grass")
	var panels := VisualAssetRegistryRef.get_ui_texture("panels")
	var comp_icon := VisualAssetRegistryRef.get_resource_icon_by_index(1, true)
	var res_icon := VisualAssetRegistryRef.get_resource_icon_by_index(1, false)
	
	assert(grass != null, "Grass tileset failed to load.")
	assert(panels != null, "Sci-Fi UI Panels failed to load.")
	assert(comp_icon != null and comp_icon.get_size() == Vector2(32, 32), "Component icon 1 should be 32x32.")
	assert(res_icon != null and res_icon.get_size() == Vector2(32, 32), "Resource icon 1 should be 32x32.")

