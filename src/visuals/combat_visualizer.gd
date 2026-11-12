class_name CombatVisualizer
extends Node2D

## Visualizes TurretEntity (static/aiming defense sprites) and EnemyEntity (animated 100x100 strips)
## with 60 FPS position interpolation (ADR-015) and health feedback.

const TICK_RATE_SEC: float = 0.1 # 10 TPS
const VisualAssetRegistryRef = preload("res://src/visuals/visual_asset_registry.gd")

var combat_entity: Object
var is_enemy: bool = false
var cell_size_pixels: float = 16.0
var time_since_tick: float = 0.0

# Enemy movement interpolation state
var previous_world_pos: Vector2 = Vector2.ZERO
var target_world_pos: Vector2 = Vector2.ZERO
var last_hp: int = -1

var turret_sprite: Sprite2D
var enemy_sprite: AnimatedSprite2D
var health_bar_bg: ColorRect
var health_bar_fill: ColorRect

func setup(p_entity: Object, p_cell_size: float = 16.0) -> void:
	combat_entity = p_entity
	cell_size_pixels = p_cell_size
	
	var entity_id: String = "turret"
	if combat_entity != null and combat_entity.get("entity_id") != null:
		entity_id = String(combat_entity.entity_id)
		
	# Detect whether this is an EnemyEntity (has speed_ticks / health) or a TurretEntity / Defense structure
	is_enemy = combat_entity != null and combat_entity.get("speed_ticks") != null
	
	var scale_factor := cell_size_pixels / float(VisualAssetRegistryRef.NATIVE_TILE_PIXELS)
	
	if is_enemy:
		enemy_sprite = AnimatedSprite2D.new()
		enemy_sprite.sprite_frames = VisualAssetRegistryRef.get_enemy_frames(entity_id)
		enemy_sprite.play("walk")
		# 100x100 padded character frames have a ~16x16 body in the center
		enemy_sprite.scale = Vector2.ONE * scale_factor
		add_child(enemy_sprite)
		
		_setup_health_bar(scale_factor)
		if combat_entity.get("health") != null:
			last_hp = int(combat_entity.health.current_health)
	else:
		turret_sprite = Sprite2D.new()
		turret_sprite.texture = VisualAssetRegistryRef.get_turret_texture(entity_id)
		# Turret textures are 32x32
		turret_sprite.scale = Vector2.ONE * (scale_factor * 0.5)
		add_child(turret_sprite)
		
	if combat_entity != null and combat_entity.get("grid_position") != null:
		target_world_pos = Vector2(combat_entity.grid_position) * cell_size_pixels
		previous_world_pos = target_world_pos
		position = target_world_pos

func on_simulation_tick() -> void:
	if combat_entity == null:
		return
		
	time_since_tick = 0.0
	
	if is_enemy:
		previous_world_pos = target_world_pos
		target_world_pos = Vector2(combat_entity.grid_position) * cell_size_pixels
		
		if enemy_sprite != null:
			var move_delta := target_world_pos - previous_world_pos
			if move_delta.x < 0.0:
				enemy_sprite.flip_h = true
			elif move_delta.x > 0.0:
				enemy_sprite.flip_h = false
				
		_update_enemy_health_and_anim()

func _process(delta: float) -> void:
	if combat_entity == null:
		return
		
	time_since_tick += delta
	if is_enemy:
		var fraction := clampf(time_since_tick / TICK_RATE_SEC, 0.0, 1.0)
		position = previous_world_pos.lerp(target_world_pos, fraction)

func _setup_health_bar(scale_factor: float) -> void:
	var bar_width := 16.0 * scale_factor
	var bar_height := 2.0 * scale_factor
	
	health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(bar_width, bar_height)
	health_bar_bg.position = Vector2(-bar_width * 0.5, -12.0 * scale_factor)
	health_bar_bg.color = Color(0.15, 0.15, 0.15, 0.85)
	health_bar_bg.visible = false
	add_child(health_bar_bg)
	
	health_bar_fill = ColorRect.new()
	health_bar_fill.size = Vector2(bar_width, bar_height)
	health_bar_fill.color = Color(0.9, 0.2, 0.2, 1.0)
	health_bar_bg.add_child(health_bar_fill)

func _update_enemy_health_and_anim() -> void:
	var health = combat_entity.get("health")
	if health == null or enemy_sprite == null:
		return
		
	var cur_hp: int = int(health.current_health)
	var max_hp: int = maxi(1, int(health.max_health))
	
	if cur_hp <= 0:
		if enemy_sprite.animation != "death":
			enemy_sprite.play("death")
		if health_bar_bg != null:
			health_bar_bg.visible = false
		return
		
	if last_hp > 0 and cur_hp < last_hp:
		enemy_sprite.play("hurt")
	elif previous_world_pos != target_world_pos:
		if enemy_sprite.animation != "walk":
			enemy_sprite.play("walk")
	else:
		if enemy_sprite.animation != "idle":
			enemy_sprite.play("idle")
			
	last_hp = cur_hp
	if health_bar_bg != null and health_bar_fill != null:
		health_bar_bg.visible = cur_hp < max_hp
		var ratio := clampf(float(cur_hp) / float(max_hp), 0.0, 1.0)
		health_bar_fill.size.x = health_bar_bg.size.x * ratio

