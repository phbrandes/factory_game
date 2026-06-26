class_name BeltVisualizer
extends Node2D

## Renders a BeltSegment and smoothly interpolates item movement at 60 FPS.

const TICK_RATE_SEC: float = 0.1 # 10 TPS

var belt_data: Object # Weak reference to the BeltSegment (using Object to avoid cyclic dependency issues in some Godot setups)
var time_since_tick: float = 0.0

# Visual state tracking
var previous_items: Array[String] = []
var current_items: Array[String] = []

# Map of array indices to visual Sprite2D nodes
var item_sprites: Dictionary = {}

# Isometric Grid Math (Assuming standard 128x64 tiles)
var tile_size_half: Vector2 = Vector2(64, 32)
var facing_vector_pixels: Vector2 = Vector2.ZERO

func setup(p_belt_data: Object, facing_dir: Vector2i) -> void:
	belt_data = p_belt_data
	
	# Convert grid direction to isometric pixel offset (for 1 tile movement)
	# Example: Moving EAST (1,0) in grid space is (64, 32) in isometric pixels.
	# For Phase 7 prototype, we map the 4 grid directions to pixel offsets.
	if facing_dir == Vector2i(1, 0): # EAST
		facing_vector_pixels = Vector2(64, 32)
	elif facing_dir == Vector2i(-1, 0): # WEST
		facing_vector_pixels = Vector2(-64, -32)
	elif facing_dir == Vector2i(0, 1): # SOUTH
		facing_vector_pixels = Vector2(-64, 32)
	elif facing_dir == Vector2i(0, -1): # NORTH
		facing_vector_pixels = Vector2(64, -32)
		
	_initialize_arrays()

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

## Manages adding/removing Sprite2D nodes based on data presence
func _update_sprites() -> void:
	for i in range(current_items.size()):
		var item_id = current_items[i]
		
		# Ensure a sprite exists for this slot if needed
		if not item_sprites.has(i):
			var new_sprite = Sprite2D.new()
			add_child(new_sprite)
			item_sprites[i] = new_sprite
			
		var sprite: Sprite2D = item_sprites[i]
		
		if item_id == "":
			sprite.visible = false
		else:
			sprite.visible = true
			# In a full build, this would map item_id to a preloaded Texture resource.
			# sprite.texture = ResourceLoader.load("res://assets/items/" + item_id + ".png")

func _initialize_arrays() -> void:
	if belt_data != null and belt_data.get("length") != null:
		var length = belt_data.length
		previous_items.resize(length)
		previous_items.fill("")
		current_items.resize(length)
		current_items.fill("")