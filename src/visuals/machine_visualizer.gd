class_name MachineVisualizer
extends Node2D

## Visualizes ProductionEntity, MinerEntity, ResearchEntity, StorageEntity, and SplitterEntity.
## Implements the 4 visual feedback states from 03_ART_BIBLE.md:
## IDLE (Waiting for input), WORKING (Processing), OUTPUT_FULL (Blocked output), and NO_POWER (Failure).

enum VisualState {
	IDLE,
	WORKING,
	OUTPUT_FULL,
	NO_POWER
}

const VisualAssetRegistryRef = preload("res://src/visuals/visual_asset_registry.gd")

var entity_data: Object
var current_state: VisualState = VisualState.IDLE
var cell_size_pixels: float = 16.0

var machine_sprite: AnimatedSprite2D
var status_sprite: Sprite2D

func setup(p_entity: Object, p_cell_size: float = 16.0) -> void:
	entity_data = p_entity
	cell_size_pixels = p_cell_size
	
	if machine_sprite == null:
		machine_sprite = AnimatedSprite2D.new()
		add_child(machine_sprite)
		
	if status_sprite == null:
		status_sprite = Sprite2D.new()
		status_sprite.texture = VisualAssetRegistryRef.get_item_texture("power")
		status_sprite.position = Vector2(0, -cell_size_pixels * 0.75)
		status_sprite.z_index = 2
		status_sprite.visible = false
		add_child(status_sprite)
		
	var entity_id: String = "assembler"
	if entity_data != null and entity_data.get("entity_id") != null:
		entity_id = String(entity_data.entity_id)
		
	machine_sprite.sprite_frames = VisualAssetRegistryRef.get_machine_frames(entity_id)
	
	# Scale relative to native 16x16 pixel art tile unit
	var scale_factor := cell_size_pixels / float(VisualAssetRegistryRef.NATIVE_TILE_PIXELS)
	machine_sprite.scale = Vector2.ONE * scale_factor
	status_sprite.scale = Vector2.ONE * (scale_factor * 0.75)
	
	# Center multi-tile footprints on orthogonal grid
	if entity_data != null and entity_data.get("size") != null:
		var footprint: Vector2i = entity_data.size
		if footprint.x > 1 or footprint.y > 1:
			machine_sprite.position = Vector2(footprint - Vector2i.ONE) * (cell_size_pixels * 0.5)
			
	on_simulation_tick()

## Synchronizes animation and status feedback on each deterministic simulation tick.
func on_simulation_tick() -> void:
	if entity_data == null:
		return
		
	current_state = _evaluate_visual_state()
	_apply_visual_state()

func _evaluate_visual_state() -> VisualState:
	# 1. Check power failure / brownout
	var power_consumer = entity_data.get("power_consumer")
	if power_consumer != null:
		if power_consumer.get("drain_per_tick") != null and power_consumer.get("buffer") != null:
			if int(power_consumer.buffer) < int(power_consumer.drain_per_tick):
				return VisualState.NO_POWER
				
	# 2. Check output inventory full or crafter stalled
	var crafter = entity_data.get("crafter")
	if crafter != null and crafter.get("current_state") != null and int(crafter.current_state) == 2:
		return VisualState.OUTPUT_FULL
	var out_inv = entity_data.get("output_inventory")
	if out_inv != null and out_inv.has_method("has_space") and not out_inv.has_space():
		return VisualState.OUTPUT_FULL
		
	# 3. Check active crafting / mining / research / splitting
	if crafter != null:
		if (crafter.get("current_state") != null and int(crafter.current_state) == 1) or (crafter.get("progress_ticks") != null and int(crafter.progress_ticks) > 0):
			return VisualState.WORKING
			
	var internal_buf = entity_data.get("_internal_buffer")
	if internal_buf != null and String(internal_buf) != "":
		return VisualState.WORKING
		
	var progression = entity_data.get("progression")
	var in_inv = entity_data.get("input_inventory")
	if progression != null and progression.get("active_research") != null and in_inv != null:
		if in_inv.get_total_items() > 0:
			return VisualState.WORKING
			
	return VisualState.IDLE

func _apply_visual_state() -> void:
	if machine_sprite == null or machine_sprite.sprite_frames == null:
		return
		
	match current_state:
		VisualState.WORKING:
			if machine_sprite.sprite_frames.has_animation("working"):
				machine_sprite.play("working")
			machine_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			status_sprite.visible = false
		VisualState.OUTPUT_FULL:
			if machine_sprite.sprite_frames.has_animation("idle"):
				machine_sprite.play("idle")
			machine_sprite.modulate = Color(1.0, 0.85, 0.4, 1.0) # Amber full-output tint
			status_sprite.visible = false
		VisualState.NO_POWER:
			if machine_sprite.sprite_frames.has_animation("idle"):
				machine_sprite.play("idle")
			machine_sprite.modulate = Color(0.65, 0.45, 0.45, 1.0) # Dimmed brownout tint
			status_sprite.visible = true
		VisualState.IDLE:
			if machine_sprite.sprite_frames.has_animation("idle"):
				machine_sprite.play("idle")
			machine_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			status_sprite.visible = false

