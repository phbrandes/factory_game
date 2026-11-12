extends Node

## Standalone test runner for Milestone 1: WorldGenerator determinism and WorldMapRenderer chunking.

const WorldGeneratorRef = preload("res://src/core/world_generator.gd")
const WorldMapRendererRef = preload("res://src/visuals/world_map_renderer.gd")

func run_tests() -> void:
	print("Running WorldGenerator & WorldMapRenderer Tests...")
	
	_test_deterministic_generation_and_order_independence()
	_test_starter_chunk_guaranteed_resources()
	_test_world_map_renderer_chunk_culling()
	
	print("All WorldGenerator & WorldMapRenderer tests passed.")

func _test_deterministic_generation_and_order_independence() -> void:
	var gen_a := WorldGeneratorRef.new(987654)
	var gen_b := WorldGeneratorRef.new(987654)
	
	# Visit chunks in opposite order on gen_a vs gen_b
	gen_a.ensure_chunk_generated(Vector2i(-1, -1))
	gen_a.ensure_chunk_generated(Vector2i(2, 1))
	
	gen_b.ensure_chunk_generated(Vector2i(2, 1))
	gen_b.ensure_chunk_generated(Vector2i(-1, -1))
	
	for x in range(-16, -10):
		for y in range(-16, -10):
			var pos := Vector2i(x, y)
			assert(gen_a.get_tile_data(pos) == gen_b.get_tile_data(pos), "Determinism broken at negative chunk coordinate: " + str(pos))
			
	for x in range(32, 40):
		for y in range(16, 24):
			var pos := Vector2i(x, y)
			assert(gen_a.get_tile_data(pos) == gen_b.get_tile_data(pos), "Determinism broken at positive chunk coordinate: " + str(pos))

func _test_starter_chunk_guaranteed_resources() -> void:
	var gen := WorldGeneratorRef.new(123)
	assert(gen.get_resource_at(Vector2i(2, 2)) == "iron_ore", "Starter chunk missing guaranteed iron_ore patch.")
	assert(gen.get_resource_at(Vector2i(2, 6)) == "copper_ore", "Starter chunk missing guaranteed copper_ore patch.")
	assert(gen.get_resource_at(Vector2i(10, 2)) == "coal", "Starter chunk missing guaranteed coal patch.")
	assert(gen.get_resource_at(Vector2i(10, 6)) == "gold_ore", "Starter chunk missing guaranteed gold_ore patch.")
	assert(gen.is_tile_walkable(Vector2i(2, 2)) == true, "Resource patch tiles must be walkable/buildable.")

func _test_world_map_renderer_chunk_culling() -> void:
	var gen := WorldGeneratorRef.new(555)
	var map_renderer := WorldMapRendererRef.new()
	add_child(map_renderer)
	map_renderer.setup(gen, 64.0)
	
	# Activate chunks (0,0) through (1,0)
	map_renderer.update_active_chunks(Vector2i(0, 0), Vector2i(1, 0))
	assert(map_renderer.get_rendered_chunk_count() == 2, "Expected 2 terrain chunks to be rendered.")
	assert(map_renderer.is_chunk_visible(Vector2i(0, 0)) == true, "Chunk (0,0) should be visible.")
	assert(map_renderer.is_chunk_visible(Vector2i(1, 0)) == true, "Chunk (1,0) should be visible.")
	
	# Move camera view to Chunk (3, 3) -> Chunks (0,0) and (1,0) should be culled
	map_renderer.update_active_chunks(Vector2i(3, 3), Vector2i(3, 3))
	assert(map_renderer.is_chunk_visible(Vector2i(0, 0)) == false, "Off-screen Chunk (0,0) should be culled.")
	assert(map_renderer.is_chunk_visible(Vector2i(3, 3)) == true, "Newly entered Chunk (3,3) should be visible.")
	
	map_renderer.queue_free()

