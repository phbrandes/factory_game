class_name WorldGenerator
extends RefCounted

## Deterministic chunk-based world and resource deposit generator.
## Uses a seeded RandomNumberGenerator and stores 16x16 chunk data in a SparseChunkGrid.
## Pure simulation data (Architecture Law 1: no visual nodes or textures).

const SparseChunkGridRef = preload("res://src/visuals/chunking/chunk_grid.gd")

const CHUNK_SIZE: int = 16

var world_seed: int = 0
var chunk_grid: SparseChunkGrid
var _generated_chunks: Dictionary = {} # Vector2i (ChunkCoord) : bool

func _init(p_seed: int = 1337, p_chunk_grid: SparseChunkGrid = null) -> void:
	world_seed = p_seed
	chunk_grid = p_chunk_grid if p_chunk_grid != null else SparseChunkGridRef.new()

## Generates all chunks within the inclusive chunk coordinate bounding box.
func generate_chunk_region(bounds_min: Vector2i, bounds_max: Vector2i) -> void:
	for cx in range(bounds_min.x, bounds_max.x + 1):
		for cy in range(bounds_min.y, bounds_max.y + 1):
			ensure_chunk_generated(Vector2i(cx, cy))

## Ensures a 16x16 chunk at c_coord is deterministically generated regardless of visit order.
func ensure_chunk_generated(c_coord: Vector2i) -> void:
	if _generated_chunks.has(c_coord):
		return
	_generated_chunks[c_coord] = true
	
	var rng := RandomNumberGenerator.new()
	rng.seed = _compute_chunk_seed(c_coord)
	
	var base_x := c_coord.x * CHUNK_SIZE
	var base_y := c_coord.y * CHUNK_SIZE
	
	# 1. Base terrain pass
	for lx in range(CHUNK_SIZE):
		for ly in range(CHUNK_SIZE):
			var global_pos := Vector2i(base_x + lx, base_y + ly)
			var roll := rng.randf()
			var terrain := "ground" if ((lx + ly) % 2 == 0) else "grass"
			var walkable := true
			
			# Avoid placing obstacles in the starter chunk (0, 0) spawn center
			var is_spawn_safe := (c_coord == Vector2i.ZERO and lx >= 1 and lx <= 14 and ly >= 1 and ly <= 14)
			if not is_spawn_safe:
				if roll < 0.04:
					terrain = "water"
					walkable = false
				elif roll < 0.08:
					terrain = "rock"
					walkable = false
				elif roll < 0.13:
					terrain = "tree"
					walkable = false
					
			chunk_grid.set_cell(global_pos, {
				"terrain": terrain,
				"resource": "",
				"walkable": walkable
			})
			
	# 2. Resource deposit veins pass
	if c_coord == Vector2i.ZERO:
		# Guaranteed starter deposits in Chunk (0, 0) for Tier 1 bootstrapping
		_stamp_resource_patch(Vector2i(2, 2), Vector2i(3, 2), "iron_ore")
		_stamp_resource_patch(Vector2i(2, 6), Vector2i(3, 2), "copper_ore")
		_stamp_resource_patch(Vector2i(10, 2), Vector2i(3, 2), "coal")
		_stamp_resource_patch(Vector2i(10, 6), Vector2i(2, 2), "gold_ore")
	else:
		var patch_count := rng.randi_range(1, 2)
		var resource_types := ["iron_ore", "copper_ore", "coal", "gold_ore"]
		for _p in range(patch_count):
			var res_type: String = resource_types[rng.randi_range(0, resource_types.size() - 1)]
			var start_x := base_x + rng.randi_range(2, CHUNK_SIZE - 5)
			var start_y := base_y + rng.randi_range(2, CHUNK_SIZE - 5)
			var size_w := rng.randi_range(2, 4)
			var size_h := rng.randi_range(2, 4)
			_stamp_resource_patch(Vector2i(start_x, start_y), Vector2i(size_w, size_h), res_type)

## Retrieves the tile dictionary at global_pos, lazily generating its chunk if needed.
func get_tile_data(global_pos: Vector2i) -> Dictionary:
	var c_coord := chunk_grid._to_chunk_coord(global_pos)
	ensure_chunk_generated(c_coord)
	var data: Variant = chunk_grid.get_cell(global_pos)
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {"terrain": "ground", "resource": "", "walkable": true}

## Returns the resource ore ID at global_pos (e.g., "iron_ore", "copper_ore", "coal", "gold_ore", or "").
func get_resource_at(global_pos: Vector2i) -> String:
	var data := get_tile_data(global_pos)
	return String(data.get("resource", ""))

## Returns true if the terrain at global_pos is walkable and buildable.
func is_tile_walkable(global_pos: Vector2i) -> bool:
	var data := get_tile_data(global_pos)
	return bool(data.get("walkable", true))

func is_chunk_generated(c_coord: Vector2i) -> bool:
	return _generated_chunks.has(c_coord)

func _stamp_resource_patch(origin: Vector2i, patch_size: Vector2i, resource_id: String) -> void:
	for dx in range(patch_size.x):
		for dy in range(patch_size.y):
			var pos := origin + Vector2i(dx, dy)
			chunk_grid.set_cell(pos, {
				"terrain": "ground",
				"resource": resource_id,
				"walkable": true
			})

func _compute_chunk_seed(c_coord: Vector2i) -> int:
	# Deterministic spatial hash combining world_seed and chunk coordinates
	var h: int = world_seed * 73856093
	h = h ^ (c_coord.x * 19349663)
	h = h ^ (c_coord.y * 83492791)
	return h

