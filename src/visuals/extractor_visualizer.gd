class_name ExtractorVisualizer
extends Node2D

## Visualizes ExtractorEntity (Robotic Arms / Inserters) at 60 FPS using ADR-015 interpolation.
## Selects the matching 48x48 directional frame from Robotic_Arms_1..3.png and renders held items.

const TICK_RATE_SEC: float = 0.1 # 10 TPS
const VisualAssetRegistryRef = preload("res://src/visuals/visual_asset_registry.gd")

var extractor_data: Object
var cell_size_pixels: float = 16.0
var tier: int = 1
var time_since_tick: float = 0.0

# 0.0 = pointing at source_pos, 1.0 = pointing at target_pos
var previous_swing_ratio: float = 0.0
var current_swing_ratio: float = 0.0
var visual_swing_ratio: float = 0.0
var current_angle_rad: float = PI

var arm_sprite: Sprite2D
var held_item_sprite: Sprite2D

func setup(p_extractor: Object, p_cell_size: float = 16.0, p_tier: int = 1) -> void:
	extractor_data = p_extractor
	cell_size_pixels = p_cell_size
	tier = p_tier
	
	if arm_sprite == null:
		arm_sprite = Sprite2D.new()
		add_child(arm_sprite)
		
	if held_item_sprite == null:
		held_item_sprite = Sprite2D.new()
		held_item_sprite.z_index = 1
		held_item_sprite.visible = false
		add_child(held_item_sprite)
		
	var scale_factor := cell_size_pixels / float(VisualAssetRegistryRef.NATIVE_TILE_PIXELS)
	arm_sprite.scale = Vector2.ONE * scale_factor
	held_item_sprite.scale = Vector2.ONE * (scale_factor * 0.75)
	
	current_swing_ratio = _compute_logical_swing_ratio()
	previous_swing_ratio = current_swing_ratio
	visual_swing_ratio = current_swing_ratio
	_update_visual_transform(visual_swing_ratio)

func on_simulation_tick() -> void:
	if extractor_data == null:
		return
		
	time_since_tick = 0.0
	previous_swing_ratio = current_swing_ratio
	current_swing_ratio = _compute_logical_swing_ratio()
	
	var held: String = String(extractor_data.get("held_item")) if extractor_data.get("held_item") != null else ""
	if held == "":
		held_item_sprite.visible = false
	else:
		held_item_sprite.visible = true
		held_item_sprite.texture = VisualAssetRegistryRef.get_item_texture(held)
		
	_update_visual_transform(previous_swing_ratio)

func _process(delta: float) -> void:
	if extractor_data == null:
		return
		
	time_since_tick += delta
	var fraction: float = clampf(time_since_tick / TICK_RATE_SEC, 0.0, 1.0)
	visual_swing_ratio = lerpf(previous_swing_ratio, current_swing_ratio, fraction)
	_update_visual_transform(visual_swing_ratio)

func _compute_logical_swing_ratio() -> float:
	if extractor_data == null:
		return 0.0
	var state: int = int(extractor_data.get("current_state"))
	var ticks_per_swing: int = maxi(1, int(extractor_data.get("ticks_per_swing")))
	var progress: int = clampi(int(extractor_data.get("progress_ticks")), 0, ticks_per_swing)
	var ratio: float = float(progress) / float(ticks_per_swing)
	
	match state:
		0: # WAITING_FOR_SOURCE
			return 0.0
		1: # SWINGING_TO_TARGET
			return ratio
		2: # WAITING_FOR_TARGET
			return 1.0
		3: # SWINGING_TO_SOURCE
			return 1.0 - ratio
		_:
			return 0.0

func _update_visual_transform(ratio: float) -> void:
	if extractor_data == null or arm_sprite == null:
		return
		
	var grid_pos: Vector2i = extractor_data.grid_position
	var source_pos: Vector2i = extractor_data.source_pos
	var target_pos: Vector2i = extractor_data.target_pos
	
	var source_vec := Vector2(source_pos - grid_pos)
	var target_vec := Vector2(target_pos - grid_pos)
	
	var source_angle := source_vec.angle() if source_vec.length_squared() > 0.0 else PI
	var target_angle := target_vec.angle() if target_vec.length_squared() > 0.0 else 0.0
	
	current_angle_rad = lerp_angle(source_angle, target_angle, ratio)
	arm_sprite.texture = VisualAssetRegistryRef.get_extractor_frame(current_angle_rad, tier)
	
	if held_item_sprite != null and held_item_sprite.visible:
		var reach_distance := cell_size_pixels * 0.75
		held_item_sprite.position = Vector2.RIGHT.rotated(current_angle_rad) * reach_distance

