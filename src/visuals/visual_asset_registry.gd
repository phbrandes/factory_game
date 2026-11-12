class_name VisualAssetRegistry
extends RefCounted

## Centralized registry and atlas slicer for all 2D textures and SpriteFrames in src/visuals/game_assets.
## Keeps simulation (src/core/) 100% decoupled from Godot rendering resources.

const BASE_PATH := "res://src/visuals/game_assets/"
const FACTORY_ASSETS_PATH := BASE_PATH + "factory assets/Assets/"
const STRUCTURES_PATH := FACTORY_ASSETS_PATH + "Structures & Machines/"
const AUTOMATION_PATH := FACTORY_ASSETS_PATH + "Automation Components/"
const ITEMS_PATH := FACTORY_ASSETS_PATH + "Item Icons/"
const TILESET_PATH := FACTORY_ASSETS_PATH + "Tileset & Environment/"
const CHARACTER_PATH := FACTORY_ASSETS_PATH + "Character/"
const DEFENSE_PATH := BASE_PATH + "defence systems assets/Defense/"
const ENEMY_SPLIT_PATH := BASE_PATH + "enemy assets/Characters(100x100 split)/"
const COMPONENTS_ICON_PATH := BASE_PATH + "components (icons) assets/Components/"
const RESOURCES_ICON_PATH := BASE_PATH + "tools and resources (icons) assets/Resources/"
const SCIFI_UI_PATH := BASE_PATH + "user interface(inventory) assets/Scifi-Ui/"

## Orthogonal grid cell size in pixels (native pixel-art tile size is 16x16, default world scale = 64x64 or 16x16).
const NATIVE_TILE_PIXELS: int = 16
const DEFAULT_CELL_PIXELS: float = 64.0

# Static caches to avoid redundant disk loads or AtlasTexture allocations
static var _texture_cache: Dictionary = {}
static var _item_atlas_cache: Dictionary = {}
static var _machine_frames_cache: Dictionary = {}
static var _belt_frames_cache: Dictionary = {}
static var _extractor_frames_cache: Dictionary = {}
static var _enemy_frames_cache: Dictionary = {}
static var _terrain_tile_cache: Dictionary = {}
static var _fallback_cache: Dictionary = {}

# Maps item_id strings to (col, row) coordinates in the 5x5 (16x16 cell) Items.png sheet
const ITEM_ATLAS_COORDS := {
	"water": Vector2i(0, 0),
	"crude_oil": Vector2i(1, 0),
	"oil": Vector2i(1, 0),
	"heavy_oil": Vector2i(2, 0),
	"acid": Vector2i(3, 0),
	"lubricant": Vector2i(3, 0),
	"light_oil": Vector2i(4, 0),
	"petroleum": Vector2i(4, 0),
	"wood": Vector2i(0, 1),
	"coal": Vector2i(1, 1),
	"stone": Vector2i(2, 1),
	"rock_ore": Vector2i(2, 1),
	"iron_ore": Vector2i(3, 1),
	"copper_ore": Vector2i(4, 1),
	"iron": Vector2i(0, 2),
	"iron_plate": Vector2i(0, 2),
	"copper": Vector2i(1, 2),
	"copper_plate": Vector2i(1, 2),
	"steel": Vector2i(2, 2),
	"steel_plate": Vector2i(2, 2),
	"steel_beam": Vector2i(2, 2),
	"copper_cable": Vector2i(3, 2),
	"copper_wire": Vector2i(3, 2),
	"wire": Vector2i(3, 2),
	"iron_gear": Vector2i(4, 2),
	"gear": Vector2i(4, 2),
	"copper_rod": Vector2i(0, 3),
	"iron_rod": Vector2i(1, 3),
	"iron_stick": Vector2i(1, 3),
	"circuit": Vector2i(2, 3),
	"circuits": Vector2i(2, 3),
	"green_circuit": Vector2i(2, 3),
	"electronic_circuit": Vector2i(2, 3),
	"red_science": Vector2i(3, 3),
	"advanced_circuit": Vector2i(3, 3),
	"red_circuit": Vector2i(3, 3),
	"blue_science": Vector2i(4, 3),
	"processing_unit": Vector2i(4, 3),
	"blue_circuit": Vector2i(4, 3),
	"silver_ore": Vector2i(0, 4),
	"gold_ore": Vector2i(1, 4),
	"power": Vector2i(2, 4),
	"energy": Vector2i(2, 4)
}

# Maps entity_id variants to machine strip definitions:
# { idle_path, working_path, frame_size: Vector2i, working_frames: int }
const MACHINE_DEFINITIONS := {
	"miner": {
		"idle": STRUCTURES_PATH + "Miner_Machine_1.png",
		"working": STRUCTURES_PATH + "Miner_Machine_1_Mining.png",
		"frame_size": Vector2i(32, 48),
		"working_frames": 4
	},
	"miner_t1": {
		"idle": STRUCTURES_PATH + "Miner_Machine_1.png",
		"working": STRUCTURES_PATH + "Miner_Machine_1_Mining.png",
		"frame_size": Vector2i(32, 48),
		"working_frames": 4
	},
	"building_miner_t1": {
		"idle": STRUCTURES_PATH + "Miner_Machine_1.png",
		"working": STRUCTURES_PATH + "Miner_Machine_1_Mining.png",
		"frame_size": Vector2i(32, 48),
		"working_frames": 4
	},
	"miner_t2": {
		"idle": STRUCTURES_PATH + "Miner_Machine_2.png",
		"working": STRUCTURES_PATH + "Miner_Machine_2_Mining.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 4
	},
	"building_miner_t2": {
		"idle": STRUCTURES_PATH + "Miner_Machine_2.png",
		"working": STRUCTURES_PATH + "Miner_Machine_2_Mining.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 4
	},
	"furnace": {
		"idle": STRUCTURES_PATH + "Stone_Furnace.png",
		"working": STRUCTURES_PATH + "Stone_Furnace_Active.png",
		"frame_size": Vector2i(32, 64),
		"working_frames": 3
	},
	"furnace_t1": {
		"idle": STRUCTURES_PATH + "Stone_Furnace.png",
		"working": STRUCTURES_PATH + "Stone_Furnace_Active.png",
		"frame_size": Vector2i(32, 64),
		"working_frames": 3
	},
	"building_furnace_t1": {
		"idle": STRUCTURES_PATH + "Stone_Furnace.png",
		"working": STRUCTURES_PATH + "Stone_Furnace_Active.png",
		"frame_size": Vector2i(32, 64),
		"working_frames": 3
	},
	"assembler": {
		"idle": STRUCTURES_PATH + "Assembler_Machine_1.png",
		"working": STRUCTURES_PATH + "Assembler_Machine_1_Running.png",
		"frame_size": Vector2i(32, 48),
		"working_frames": 4
	},
	"assembler_t1": {
		"idle": STRUCTURES_PATH + "Assembler_Machine_1.png",
		"working": STRUCTURES_PATH + "Assembler_Machine_1_Running.png",
		"frame_size": Vector2i(32, 48),
		"working_frames": 4
	},
	"assembler_t2": {
		"idle": STRUCTURES_PATH + "Assembler_Machine_2.png",
		"working": STRUCTURES_PATH + "Assembler_Machine_2_Running.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 4
	},
	"assembler_t3": {
		"idle": STRUCTURES_PATH + "Assembler_Machine_3.png",
		"working": STRUCTURES_PATH + "Assembler_Machine_3_Running.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 4
	},
	"assembler_t4": {
		"idle": STRUCTURES_PATH + "Assembler_Machine_4.png",
		"working": STRUCTURES_PATH + "Assembler_Machine_4_Running.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 4
	},
	"research_lab": {
		"idle": STRUCTURES_PATH + "Assembler_Machine_3.png",
		"working": STRUCTURES_PATH + "Assembler_Machine_3_Running.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 4
	},
	"lab": {
		"idle": STRUCTURES_PATH + "Assembler_Machine_3.png",
		"working": STRUCTURES_PATH + "Assembler_Machine_3_Running.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 4
	},
	"boiler": {
		"idle": STRUCTURES_PATH + "Boiler.png",
		"working": STRUCTURES_PATH + "Boiler_Running.png",
		"frame_size": Vector2i(64, 48),
		"working_frames": 2
	},
	"steam_engine": {
		"idle": STRUCTURES_PATH + "Steam_Engine.png",
		"working": STRUCTURES_PATH + "Steam_Engine_Running.png",
		"frame_size": Vector2i(96, 80),
		"working_frames": 4
	},
	"water_pump": {
		"idle": STRUCTURES_PATH + "Water_Pump.png",
		"working": STRUCTURES_PATH + "Water_Pump_Running.png",
		"frame_size": Vector2i(48, 32),
		"working_frames": 2
	},
	"solar_panel": {
		"idle": STRUCTURES_PATH + "Small_Solar_Panel.png",
		"working": STRUCTURES_PATH + "Small_Solar_Panel.png",
		"frame_size": Vector2i(32, 48),
		"working_frames": 1
	},
	"solar_panel_t2": {
		"idle": STRUCTURES_PATH + "Big_Solar_Panel.png",
		"working": STRUCTURES_PATH + "Big_Solar_Panel.png",
		"frame_size": Vector2i(32, 48),
		"working_frames": 1
	},
	"storage": {
		"idle": AUTOMATION_PATH + "Crate.png",
		"working": AUTOMATION_PATH + "Crate.png",
		"frame_size": Vector2i(16, 16),
		"working_frames": 1
	},
	"storage_t1": {
		"idle": AUTOMATION_PATH + "Crate.png",
		"working": AUTOMATION_PATH + "Crate.png",
		"frame_size": Vector2i(16, 16),
		"working_frames": 1
	},
	"storage_t2": {
		"idle": AUTOMATION_PATH + "Metal_Crate.png",
		"working": AUTOMATION_PATH + "Metal_Crate.png",
		"frame_size": Vector2i(16, 16),
		"working_frames": 1
	},
	"splitter": {
		"idle": AUTOMATION_PATH + "Splitter_A.png",
		"working": AUTOMATION_PATH + "Splitter_A.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 1
	},
	"splitter_t1": {
		"idle": AUTOMATION_PATH + "Splitter_A.png",
		"working": AUTOMATION_PATH + "Splitter_A.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 1
	},
	"splitter_t2": {
		"idle": AUTOMATION_PATH + "Splitter_B.png",
		"working": AUTOMATION_PATH + "Splitter_B.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 1
	},
	"splitter_t3": {
		"idle": AUTOMATION_PATH + "Splitter_C.png",
		"working": AUTOMATION_PATH + "Splitter_C.png",
		"frame_size": Vector2i(48, 48),
		"working_frames": 1
	},
	"electric_pole": {
		"idle": AUTOMATION_PATH + "Electric_Pole.png",
		"working": AUTOMATION_PATH + "Electric_Pole.png",
		"frame_size": Vector2i(32, 48),
		"working_frames": 1
	},
	"tall_electric_pole": {
		"idle": AUTOMATION_PATH + "Tall_Electric_Pole.png",
		"working": AUTOMATION_PATH + "Tall_Electric_Pole.png",
		"frame_size": Vector2i(32, 64),
		"working_frames": 1
	}
}

# Maps defense/turret entity_ids to defence systems assets/Defense/1.png..36.png
const DEFENSE_TEXTURE_MAP := {
	"turret": DEFENSE_PATH + "1.png",
	"turret_gun_t1": DEFENSE_PATH + "1.png",
	"turret_gun_t2": DEFENSE_PATH + "2.png",
	"turret_gun_t3": DEFENSE_PATH + "21.png",
	"turret_gun_t4": DEFENSE_PATH + "30.png",
	"turret_laser_t1": DEFENSE_PATH + "20.png",
	"turret_missile_t1": DEFENSE_PATH + "23.png",
	"turret_mortar_t1": DEFENSE_PATH + "31.png",
	"defence_wall_t1": DEFENSE_PATH + "10.png",
	"defence_wall_t2": DEFENSE_PATH + "11.png",
	"defence_wall_t3": DEFENSE_PATH + "12.png",
	"defence_wall_t4": DEFENSE_PATH + "19.png",
	"defence_building_t1": DEFENSE_PATH + "4.png",
	"defence_building_t2": DEFENSE_PATH + "8.png",
	"defence_building_t3": DEFENSE_PATH + "9.png",
	"defence_building_t4": DEFENSE_PATH + "22.png"
}

# Maps enemy_id strings to folder and file prefix under Characters(100x100 split)/
const ENEMY_DEFINITIONS := {
	"slime": {"folder": "Slime", "prefix": "Slime"},
	"orc": {"folder": "Orc", "prefix": "Orc"},
	"armored_orc": {"folder": "Armored Orc", "prefix": "Armored Orc"},
	"elite_orc": {"folder": "Elite Orc", "prefix": "Elite Orc"},
	"orc_rider": {"folder": "Orc rider", "prefix": "Orc rider"},
	"skeleton": {"folder": "Skeleton", "prefix": "Skeleton"},
	"armored_skeleton": {"folder": "Armored Skeleton", "prefix": "Armored Skeleton"},
	"greatsword_skeleton": {"folder": "Greatsword Skeleton", "prefix": "Greatsword Skeleton"},
	"skeleton_archer": {"folder": "Skeleton Archer", "prefix": "Skeleton Archer"},
	"necromancer": {"folder": "Necromancer", "prefix": "Necromancer"},
	"bat": {"folder": "Bat", "prefix": "Bat"},
	"werewolf": {"folder": "Werewolf", "prefix": "Werewolf"},
	"werebear": {"folder": "Werebear", "prefix": "Werebear"},
	"archer": {"folder": "Archer", "prefix": "Archer"},
	"knight": {"folder": "Knight", "prefix": "Knight"},
	"knight_templar": {"folder": "Knight Templar", "prefix": "Knight Templar"},
	"lancer": {"folder": "Lancer", "prefix": "Lancer"},
	"priest": {"folder": "Priest", "prefix": "Priest"},
	"soldier": {"folder": "Soldier", "prefix": "Soldier"},
	"swordsman": {"folder": "Swordsman", "prefix": "Swordsman"},
	"wizard": {"folder": "Wizard", "prefix": "Wizard"},
	"armored_axeman": {"folder": "Armored Axeman", "prefix": "Armored Axeman"}
}

## Safely loads a Texture2D from disk (using ResourceLoader first, falling back to Image.loadFromFile for unimported tests).
static func load_texture(res_path: String) -> Texture2D:
	if _texture_cache.has(res_path):
		return _texture_cache[res_path]
		
	var tex: Texture2D = null
	if ResourceLoader.exists(res_path):
		tex = ResourceLoader.load(res_path) as Texture2D
		
	if tex == null and FileAccess.file_exists(res_path):
		var img := Image.new()
		var abs_path := ProjectSettings.globalize_path(res_path)
		if img.load(abs_path) == OK:
			tex = ImageTexture.create_from_image(img)
			
	if tex != null:
		_texture_cache[res_path] = tex
	return tex

## Returns a 16x16 AtlasTexture for the given item_id from Items.png (or a fallback texture).
static func get_item_texture(item_id: String) -> Texture2D:
	var key := item_id.to_lower()
	if _item_atlas_cache.has(key):
		return _item_atlas_cache[key]
		
	if key == "gold_ore":
		var gold_tex := load_texture(ITEMS_PATH + "Gold_Ore.png")
		if gold_tex != null:
			_item_atlas_cache[key] = gold_tex
			return gold_tex
	elif key == "rock_ore":
		var rock_tex := load_texture(ITEMS_PATH + "Rock_Ore.png")
		if rock_tex != null:
			_item_atlas_cache[key] = rock_tex
			return rock_tex
			
	var sheet := load_texture(ITEMS_PATH + "Items.png")
	if sheet != null and ITEM_ATLAS_COORDS.has(key):
		var coords: Vector2i = ITEM_ATLAS_COORDS[key]
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(coords.x * 16, coords.y * 16, 16, 16)
		_item_atlas_cache[key] = atlas
		return atlas
		
	# Fallback procedural icon following 03_ART_BIBLE.md color language
	var fallback := _get_or_create_fallback_texture(key, Vector2i(16, 16))
	_item_atlas_cache[key] = fallback
	return fallback

## Returns a 32x32 high-res icon from tools and resources / components packs by 1-based index.
static func get_resource_icon_by_index(index: int, is_component: bool = false) -> Texture2D:
	var clamped_idx := clampi(index, 1, 64 if is_component else 81)
	var base := COMPONENTS_ICON_PATH if is_component else RESOURCES_ICON_PATH
	var tex := load_texture(base + str(clamped_idx) + ".png")
	if tex != null:
		return tex
	return _get_or_create_fallback_texture("icon_" + str(index), Vector2i(32, 32))

## Returns SpriteFrames with "idle" and "working" animations for a production/mining/storage/power machine.
static func get_machine_frames(entity_id: String) -> SpriteFrames:
	var key := _normalize_machine_key(entity_id)
	if _machine_frames_cache.has(key):
		return _machine_frames_cache[key]
		
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
		
	frames.add_animation("idle")
	frames.set_animation_loop("idle", false)
	frames.set_animation_speed("idle", 1.0)
	
	frames.add_animation("working")
	frames.set_animation_loop("working", true)
	frames.set_animation_speed("working", 8.0)
	
	if MACHINE_DEFINITIONS.has(key):
		var def: Dictionary = MACHINE_DEFINITIONS[key]
		var idle_tex := load_texture(def["idle"])
		if idle_tex != null:
			frames.add_frame("idle", idle_tex)
			
		var working_tex := load_texture(def["working"])
		var frame_size: Vector2i = def["frame_size"]
		var count: int = def["working_frames"]
		if working_tex != null:
			if count <= 1:
				frames.add_frame("working", working_tex)
			else:
				for i in range(count):
					var atlas := AtlasTexture.new()
					atlas.atlas = working_tex
					atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
					frames.add_frame("working", atlas)
	else:
		var fallback := _get_or_create_fallback_texture(key, Vector2i(32, 32))
		frames.add_frame("idle", fallback)
		frames.add_frame("working", fallback)
		
	_machine_frames_cache[key] = frames
	return frames

## Returns a single static preview Texture2D for any entity_id (for build ghosts, UI slots, or static sprites).
static func get_entity_preview_texture(entity_id: String) -> Texture2D:
	var lower := entity_id.to_lower()
	if lower.begins_with("belt") or lower.begins_with("conveyor"):
		var belt_frames := get_belt_frames(1, Vector2i(1, 0))
		if belt_frames.get_frame_count("move") > 0:
			return belt_frames.get_frame_texture("move", 0)
	elif lower.begins_with("extractor") or lower.begins_with("inserter") or lower.begins_with("robotic_arm"):
		return get_extractor_frame(0.0, 1)
	elif DEFENSE_TEXTURE_MAP.has(lower) or lower.begins_with("turret") or lower.begins_with("defence") or lower.begins_with("defense"):
		return get_turret_texture(lower)
	elif ENEMY_DEFINITIONS.has(lower):
		var ef := get_enemy_frames(lower)
		if ef.get_frame_count("idle") > 0:
			return ef.get_frame_texture("idle", 0)
			
	var key := _normalize_machine_key(lower)
	if MACHINE_DEFINITIONS.has(key):
		var tex := load_texture(MACHINE_DEFINITIONS[key]["idle"])
		if tex != null:
			return tex
			
	return _get_or_create_fallback_texture(lower, Vector2i(32, 32))

## Returns SpriteFrames ("move" animation, 8 frames of 16x16) for a conveyor belt in a given grid direction.
static func get_belt_frames(tier: int = 1, facing_dir: Vector2i = Vector2i(1, 0)) -> SpriteFrames:
	var cache_key := "%d_%d_%d" % [tier, facing_dir.x, facing_dir.y]
	if _belt_frames_cache.has(cache_key):
		return _belt_frames_cache[cache_key]
		
	var suffix := ""
	match clampi(tier, 1, 4):
		2: suffix = "_B"
		3: suffix = "_C"
		4: suffix = "_D"
		_: suffix = ""
		
	var sheet := load_texture(AUTOMATION_PATH + "Conveyor_Belt" + suffix + ".png")
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("move")
	frames.set_animation_loop("move", true)
	frames.set_animation_speed("move", 12.0)
	
	# Conveyor_Belt.png is 768x64: 8 animation blocks of 96x64 pixels.
	# Inside each 96x64 block:
	# - EAST  (1, 0):  offset (0, 32), size (16, 16)
	# - WEST  (-1, 0): offset (0, 48), size (16, 16)
	# - NORTH (0, -1): offset (32, 0), size (16, 16)
	# - SOUTH (0, 1):  offset (48, 0), size (16, 16)
	var sub_offset := Vector2i(0, 32)
	if facing_dir == Vector2i(-1, 0):
		sub_offset = Vector2i(0, 48)
	elif facing_dir == Vector2i(0, -1):
		sub_offset = Vector2i(32, 0)
	elif facing_dir == Vector2i(0, 1):
		sub_offset = Vector2i(48, 0)
		
	if sheet != null:
		for frame_idx in range(8):
			var block_x := frame_idx * 96
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(block_x + sub_offset.x, sub_offset.y, 16, 16)
			frames.add_frame("move", atlas)
	else:
		frames.add_frame("move", _get_or_create_fallback_texture("belt", Vector2i(16, 16)))
		
	_belt_frames_cache[cache_key] = frames
	return frames

## Returns the 8 directional AtlasTextures (48x48 each) for Robotic_Arms_1..3.png.
## Frame order in Robotic_Arms_1.png (clockwise from West):
## 0: W (-1,0), 1: NW (-1,-1), 2: N (0,-1), 3: NE (1,-1),
## 4: E (1,0),  5: SE (1,1),   6: S (0,1),  7: SW (-1,1)
static func get_extractor_frames(tier: int = 1) -> Array[Texture2D]:
	var clamped_tier := clampi(tier, 1, 3)
	if _extractor_frames_cache.has(clamped_tier):
		return _extractor_frames_cache[clamped_tier]
		
	var sheet := load_texture(AUTOMATION_PATH + "Robotic_Arms_" + str(clamped_tier) + ".png")
	var result: Array[Texture2D] = []
	if sheet != null:
		for i in range(8):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * 48, 0, 48, 48)
			result.append(atlas)
	else:
		var fb := _get_or_create_fallback_texture("extractor", Vector2i(48, 48))
		for i in range(8):
			result.append(fb)
			
	_extractor_frames_cache[clamped_tier] = result
	return result

## Returns the closest 48x48 Robotic Arm directional frame for a given angle in radians
## (where 0 = East, PI/2 = South, PI or -PI = West, -PI/2 = North).
static func get_extractor_frame(angle_rad: float, tier: int = 1) -> Texture2D:
	var frames := get_extractor_frames(tier)
	# Shift angle so West (PI) maps to index 0 and moves clockwise
	var normalized := fposmod(angle_rad + PI, TAU)
	var sector := int(round(normalized / (TAU / 8.0))) % 8
	return frames[sector]

## Returns a 32x32 Texture2D for a turret or defense building.
static func get_turret_texture(entity_id: String) -> Texture2D:
	var key := entity_id.to_lower()
	if DEFENSE_TEXTURE_MAP.has(key):
		var tex := load_texture(DEFENSE_TEXTURE_MAP[key])
		if tex != null:
			return tex
	# Default to Defense/1.png if any turret_* ID is requested
	var default_tex := load_texture(DEFENSE_PATH + "1.png")
	if default_tex != null:
		return default_tex
	return _get_or_create_fallback_texture(key, Vector2i(32, 32))

## Returns SpriteFrames ("idle", "walk", "attack", "hurt", "death") sliced from the 100x100 enemy strips.
static func get_enemy_frames(enemy_id: String, with_shadows: bool = true) -> SpriteFrames:
	var key := enemy_id.to_lower()
	if not ENEMY_DEFINITIONS.has(key):
		key = "orc" # Default enemy sprite family if generic "enemy" or "biter" is passed
		
	var cache_key := key + ("_shadow" if with_shadows else "_noshadow")
	if _enemy_frames_cache.has(cache_key):
		return _enemy_frames_cache[cache_key]
		
	var def: Dictionary = ENEMY_DEFINITIONS[key]
	var folder: String = def["folder"]
	var prefix: String = def["prefix"]
	var sub_folder := (folder + " with shadows") if with_shadows else folder
	var dir_path := ENEMY_SPLIT_PATH + folder + "/" + sub_folder + "/"
	
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
		
	var anim_map := {
		"idle": {"suffix": "_Idle.png", "loop": true, "fps": 8.0},
		"walk": {"suffix": "_Walk.png", "loop": true, "fps": 10.0},
		"attack": {"suffix": "_Attack01.png", "loop": false, "fps": 10.0},
		"hurt": {"suffix": "_Hurt.png", "loop": false, "fps": 8.0},
		"death": {"suffix": "_Death.png", "loop": false, "fps": 8.0}
	}
	
	for anim_name in anim_map.keys():
		var info: Dictionary = anim_map[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, info["loop"])
		frames.set_animation_speed(anim_name, info["fps"])
		
		var strip_path: String = dir_path + prefix + String(info["suffix"])
		var strip_tex := load_texture(strip_path)
		if strip_tex == null:
			# Fallback to non-shadow directory if shadow naming differs
			strip_path = ENEMY_SPLIT_PATH + folder + "/" + folder + "/" + prefix + info["suffix"]
			strip_tex = load_texture(strip_path)
			
		if strip_tex != null:
			var frame_count := maxi(1, int(strip_tex.get_width() / 100))
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas = strip_tex
				atlas.region = Rect2(i * 100, 0, 100, 100)
				frames.add_frame(anim_name, atlas)
		else:
			frames.add_frame(anim_name, _get_or_create_fallback_texture(key, Vector2i(32, 32)))
			
	_enemy_frames_cache[cache_key] = frames
	return frames

## Returns environment / terrain textures from factory assets/Assets/Tileset & Environment/.
static func get_terrain_texture(terrain_id: String) -> Texture2D:
	var map := {
		"ground": TILESET_PATH + "Ground_Tile.png",
		"grass": TILESET_PATH + "Grass_Tileset.png",
		"water": TILESET_PATH + "Water_Tileset.png",
		"iron_ore": TILESET_PATH + "Iron_Ore_Tiles.png",
		"coal": TILESET_PATH + "Coal_Tiles.png",
		"copper_ore": TILESET_PATH + "Copper_Rock.png",
		"gold_ore": TILESET_PATH + "Gold_Rock.png",
		"rock": TILESET_PATH + "Rock_Tile.png",
		"tree": TILESET_PATH + "Tree.png",
		"trees": TILESET_PATH + "Trees.png"
	}
	var path: String = map.get(terrain_id.to_lower(), TILESET_PATH + "Ground_Tile.png")
	var tex := load_texture(path)
	if tex != null:
		return tex
	return _get_or_create_fallback_texture(terrain_id, Vector2i(16, 16))

## Returns a single 16x16 tile Texture2D (slicing 3x3 autotile sheets like Iron_Ore_Tiles.png or Coal_Tiles.png to their center 16x16 tile).
static func get_terrain_tile_texture(terrain_id: String) -> Texture2D:
	var key := terrain_id.to_lower()
	if _terrain_tile_cache.has(key):
		return _terrain_tile_cache[key]
		
	var raw_tex := get_terrain_texture(key)
	if raw_tex == null:
		return _get_or_create_fallback_texture(key, Vector2i(16, 16))
		
	# Single 16x16 textures (Ground_Tile, Rock_Tile, Copper_Rock, Gold_Rock) or Tree (32x48)
	if key in ["ground", "rock", "copper_ore", "gold_ore", "tree"]:
		_terrain_tile_cache[key] = raw_tex
		return raw_tex
		
	# 3x3 autotile sheets (Iron_Ore_Tiles 48x48, Coal_Tiles 48x48, Grass_Tileset 80x48, Water_Tileset 80x48):
	# Slice the center 16x16 tile at (16, 16)
	if raw_tex.get_width() >= 32 and raw_tex.get_height() >= 32:
		var atlas := AtlasTexture.new()
		atlas.atlas = raw_tex
		atlas.region = Rect2(16, 16, 16, 16)
		_terrain_tile_cache[key] = atlas
		return atlas
		
	_terrain_tile_cache[key] = raw_tex
	return raw_tex

## Returns Sci-Fi UI textures from user interface(inventory) assets/Scifi-Ui/.
static func get_ui_texture(ui_element: String) -> Texture2D:
	var map := {
		"panels": SCIFI_UI_PATH + "Panels/Panels.png",
		"slots": SCIFI_UI_PATH + "Slots/Slots.png",
		"bars": SCIFI_UI_PATH + "Bars/Bars.png",
		"buttons": SCIFI_UI_PATH + "Buttons/Buttons.png",
		"icons": SCIFI_UI_PATH + "Icons/Icons.png",
		"minimap": SCIFI_UI_PATH + "Minimap/Minimap.png",
		"portrait": SCIFI_UI_PATH + "Portrait/Portrait.png",
		"decoration": SCIFI_UI_PATH + "Decoration/Decoration.png"
	}
	var path: String = map.get(ui_element.to_lower(), SCIFI_UI_PATH + "Panels/Panels.png")
	var tex := load_texture(path)
	if tex != null:
		return tex
	return _get_or_create_fallback_texture(ui_element, Vector2i(32, 32))

static func _normalize_machine_key(entity_id: String) -> String:
	var lower := entity_id.to_lower()
	if MACHINE_DEFINITIONS.has(lower):
		return lower
	if lower.contains("miner"):
		return "miner_t2" if lower.contains("2") else "miner_t1"
	if lower.contains("furnace"):
		return "furnace_t1"
	if lower.contains("assembler"):
		if lower.contains("4"): return "assembler_t4"
		if lower.contains("3"): return "assembler_t3"
		if lower.contains("2"): return "assembler_t2"
		return "assembler_t1"
	if lower.contains("splitter"):
		if lower.contains("3"): return "splitter_t3"
		if lower.contains("2"): return "splitter_t2"
		return "splitter_t1"
	if lower.contains("storage") or lower.contains("chest") or lower.contains("crate"):
		return "storage_t1"
	if lower.contains("research") or lower.contains("lab"):
		return "research_lab"
	if lower.contains("solar"):
		return "solar_panel"
	if lower.contains("steam"):
		return "steam_engine"
	if lower.contains("boiler"):
		return "boiler"
	return lower

## Generates a deterministic solid-color ImageTexture adhering to 03_ART_BIBLE.md color language.
static func _get_or_create_fallback_texture(id: String, size: Vector2i) -> Texture2D:
	var cache_key := "%s_%dx%d" % [id, size.x, size.y]
	if _fallback_cache.has(cache_key):
		return _fallback_cache[cache_key]
		
	var color := Color(0.55, 0.58, 0.62, 1.0) # Default Iron Gray
	if id.contains("copper"):
		color = Color(0.85, 0.45, 0.2, 1.0) # Copper Orange
	elif id.contains("power") or id.contains("solar") or id.contains("electric"):
		color = Color(0.95, 0.85, 0.2, 1.0) # Power Yellow
	elif id.contains("enemy") or id.contains("orc") or id.contains("slime"):
		color = Color(0.85, 0.2, 0.2, 1.0) # Enemy Red
	elif id.contains("boss") or id.contains("necromancer"):
		color = Color(0.6, 0.2, 0.8, 1.0) # Boss Purple
	elif id.contains("player"):
		color = Color(0.2, 0.5, 0.9, 1.0) # Player Blue
		
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex := ImageTexture.create_from_image(img)
	_fallback_cache[cache_key] = tex
	return tex

