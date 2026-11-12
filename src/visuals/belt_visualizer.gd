class_name BeltVisualizer
extends Node2D

## Renders a BeltSegment and smoothly interpolates item movement at 60 FPS.
## Supports orthogonal pixel-art grid alignment (default in FactoryRenderer) as well as legacy isometric test math.

const TICK_RATE_SEC: float = 0.1 # 10 TPS
const VisualAssetRegistryRef = preload("res://src/visuals/visual_asset_registry.gd")

var belt_data: Object # Weak reference to the BeltSegment
var time_since_tick: float = 0.0

# Visual state tracking
var previous_items: Array[String] = []
var current_items: Array[String] = []

# Map of array indices to visual Sprite2D nodes for items on the belt
var item_sprites: Dictionary = {}
# Map of array indices to AnimatedSprite2D nodes for the conveyor track tiles
var track_sprites: Dictionary = {}

# Grid Math
var use_orthogonal: bool = false
var cell_size_pixels: float = 16.0
var tile_size_half: Vector2 = Vector2(64, 32)
var facing_vector_pixels: Vector2 = Vector2.ZERO
var facing_direction: Vector2i = Vector2i(1, 0)
var belt_tier: int = 1

func setup(p_belt_data: Object, facing_dir: Vector2i, p_orthogonal: bool = false, p_cell_size: float = 16.0, p_tier: int = 1) -> void:
	belt_data = p_belt_data
	facing_direction = facing_dir
	use_orthogonal = p_orthogonal
	cell_size_pixels = p_cell_size
	belt_tier = p_tier
	
	if use_orthogonal:
		facing_vector_pixels = Vector2(facing_dir) * cell_size_pixels
	else:
		# Legacy isometric pixel offsets (used by belt_visualizer_test.gd)
		if facing_dir == Vector2i(1, 0): # EAST
			facing_vector_pixels = Vector2(64, 32)
		elif facing_dir == Vector2i(-1, 0): # WEST
			facing_vector_pixels = Vector2(-64, -32)
		elif facing_dir == Vector2i(0, 1): # SOUTH
			facing_vector_pixels = Vector2(-64, 32)
		elif facing_dir == Vector2i(0, -1): # NORTH
			facing_vector_pixels = Vector2(64, -32)
		
	_initialize_arrays()
	_rebuild_track_sprites()
	_update_sprites()

## Convenience initializer for orthogonal alignment used by FactoryRenderer.
func setup_orthogonal(p_belt_data: Object, facing_dir: Vector2i = Vector2i(1, 0), p_cell_size: float = 16.0, p_tier: int = 1) -> void:
	setup(p_belt_data, facing_dir, true, p_cell_size, p_tier)

## Triggered by FactoryRenderer when the TickScheduler fires.
func on_simulation_tick() -> void:
	time_since_tick = 0.0
	
	# Cache old state and fetch new state
	previous_items = current_items.duplicate()
	if belt_data != null and belt_data.get("items") != null:
		current_items = belt_data.items.duplicate()
	else:
		current_items.fill("")
		
	_update_sprites()

func _process(delta: float) -> void:
	if belt_data == null:
		return
		
	time_since_tick += delta
	var fraction: float = clampf(time_since_tick / TICK_RATE_SEC, 0.0, 1.0)
	
	# Interpolate positions for every physical slot on this belt segment
	for i in range(current_items.size()):
		var sprite: Sprite2D = item_sprites.get(i)
		if sprite != null and sprite.visible:
			
			var target_pos: Vector2 = _get_local_pixel_pos_for_index(i)
			
			# If the item was AT THIS INDEX previously, it didn't move (blocked).
			if previous_items[i] == current_items[i] and current_items[i] != "":
				sprite.position = target_pos
				
			# If it just arrived here, it came from the index behind it.
			elif i > 0 and previous_items[i-1] == current_items[i] and current_items[i] != "":
				var start_pos: Vector2 = _get_local_pixel_pos_for_index(i - 1)
				sprite.position = start_pos.lerp(target_pos, fraction)
				
			# If it just entered index 0 from another machine/belt, interpolate from the entry edge
			elif i == 0 and previous_items[0] != current_items[0] and current_items[0] != "":
				var start_pos: Vector2 = target_pos - facing_vector_pixels
				sprite.position = start_pos.lerp(target_pos, fraction)

## Converts an array index (0, 1, 2) into a local Vector2 pixel position along the belt's length.
func _get_local_pixel_pos_for_index(index: int) -> Vector2:
	# Local origin (0,0) is the center of the first tile (index 0).
	return facing_vector_pixels * index

## Creates AnimatedSprite2D conveyor track segments along the belt's length.
func _rebuild_track_sprites() -> void:
	for sprite in track_sprites.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	track_sprites.clear()
	
	var frames := VisualAssetRegistryRef.get_belt_frames(belt_tier, facing_direction)
	var scale_factor := (cell_size_pixels / float(VisualAssetRegistryRef.NATIVE_TILE_PIXELS)) if use_orthogonal else 1.0
	
	for i in range(current_items.size()):
		var track := AnimatedSprite2D.new()
		track.sprite_frames = frames
		track.animation = "move"
		track.play("move")
		track.position = _get_local_pixel_pos_for_index(i)
		track.scale = Vector2.ONE * scale_factor
		track.z_index = 0
		add_child(track)
		track_sprites[i] = track

## Manages adding/removing Sprite2D nodes based on data presence and assigns item textures.
func _update_sprites() -> void:
	var scale_factor := (cell_size_pixels / float(VisualAssetRegistryRef.NATIVE_TILE_PIXELS)) if use_orthogonal else 1.0
	for i in range(current_items.size()):
		var item_id = current_items[i]
		
		# Ensure a sprite exists for this slot if needed
		if not item_sprites.has(i):
			var new_sprite = Sprite2D.new()
			new_sprite.z_index = 1
			add_child(new_sprite)
			item_sprites[i] = new_sprite
			
		var sprite: Sprite2D = item_sprites[i]
		sprite.scale = Vector2.ONE * scale_factor
		
		if item_id == "":
			sprite.visible = false
		else:
			sprite.visible = true
			sprite.texture = VisualAssetRegistryRef.get_item_texture(item_id)

func _initialize_arrays() -> void:
	if belt_data != null and belt_data.get("length") != null:
		var length = belt_data.length
		previous_items.resize(length)
		previous_items.fill("")
		current_items.resize(length)
		current_items.fill("")
