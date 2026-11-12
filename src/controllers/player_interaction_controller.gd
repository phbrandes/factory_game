extends Node2D

## Handles mouse tracking, grid snapping, and routing inputs to the simulation.

const VisualAssetRegistryRef = preload("res://src/visuals/visual_asset_registry.gd")

var grid: GridManager
var replay_system
var scheduler: Node # TickScheduler reference
var tile_map: TileMapLayer
var radial_menu

var current_build_item_id: String = ""
var ghost_sprite: Sprite2D
var cell_size_pixels: float = 64.0

func setup(p_grid: GridManager, p_replay, p_scheduler: Node, p_tile_map: TileMapLayer, p_menu) -> void:
	grid = p_grid
	replay_system = p_replay
	scheduler = p_scheduler
	tile_map = p_tile_map
	radial_menu = p_menu
	
	_setup_ghost_sprite()
	
	# Connect to the UI signal
	radial_menu.item_selected.connect(_on_build_item_selected)

func _setup_ghost_sprite() -> void:
	ghost_sprite = Sprite2D.new()
	ghost_sprite.modulate = Color(0.2, 1.0, 0.2, 0.5) # Semi-transparent green
	add_child(ghost_sprite)
	ghost_sprite.hide()

func _process(_delta: float) -> void:
	if current_build_item_id == "" or radial_menu.is_open:
		ghost_sprite.hide()
		return
		
	ghost_sprite.show()
	var mouse_world_pos = get_global_mouse_position()
	var grid_pos := Vector2i.ZERO
	
	if tile_map != null:
		grid_pos = tile_map.local_to_map(mouse_world_pos)
		var snap_world_pos = tile_map.map_to_local(grid_pos)
		ghost_sprite.global_position = snap_world_pos
	else:
		grid_pos = Vector2i((mouse_world_pos / cell_size_pixels).floor())
		ghost_sprite.global_position = Vector2(grid_pos) * cell_size_pixels
		
	if grid != null:
		if grid.is_area_empty(grid_pos, Vector2i.ONE):
			ghost_sprite.modulate = Color(0.2, 1.0, 0.2, 0.5) # Valid placement (green)
		else:
			ghost_sprite.modulate = Color(1.0, 0.2, 0.2, 0.5) # Blocked placement (red)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_right_click"):
		if current_build_item_id != "":
			# Cancel building mode
			current_build_item_id = ""
			ghost_sprite.hide()
		else:
			# Open radial menu if not building
			var screen_pos = get_viewport().get_mouse_position()
			var available_buildings = ["belt_t1", "miner_t1", "furnace_t1", "assembler_t1"]
			radial_menu.open(screen_pos, available_buildings)
			
	elif event.is_action_pressed("ui_left_click"):
		if radial_menu.is_open:
			radial_menu.close()
		elif current_build_item_id != "":
			_attempt_placement()

func _attempt_placement() -> void:
	if tile_map == null or grid == null:
		return
		
	var mouse_world_pos = get_global_mouse_position()
	var grid_pos = tile_map.local_to_map(mouse_world_pos)
	
	var GridEntityRef = load("res://src/core/grid_entity.gd")
	var new_entity = GridEntityRef.new(current_build_item_id)
	
	if grid.is_area_empty(grid_pos, new_entity.size):
		# Log for deterministic replay
		var tick = scheduler.get_current_tick() if scheduler.has_method("get_current_tick") else 0
		var payload = {"x": grid_pos.x, "y": grid_pos.y, "id": current_build_item_id}
		replay_system.record_action(tick, "place_entity", payload)
		
		# Execute simulation action
		grid.place_entity(new_entity, grid_pos)
	else:
		print("Placement blocked by existing entity.")

func _on_build_item_selected(item_id: String) -> void:
	current_build_item_id = item_id
	if ghost_sprite != null:
		ghost_sprite.texture = VisualAssetRegistryRef.get_entity_preview_texture(item_id)
