extends Node

## Standalone test runner for deterministic turret targeting and cooldown logic.

const TurretEntityRef = preload("res://src/core/combat/turret_entity.gd")
const EnemyEntityRef = preload("res://src/core/combat/enemy_entity.gd")

func run_tests() -> void:
	print("Running Turret Targeting Tests...")
	
	_test_deterministic_priority()
	_test_fire_rate_cooldown()
	
	print("All Turret Targeting tests passed.")

func _test_deterministic_priority() -> void:
	# Turret: Range 5, Damage 10
	var turret = TurretEntityRef.new("turret_t1", 5, 10)
	turret.grid_position = Vector2i(0, 0)
	
	# Enemy A: Created tick 100, HP 30
	var enemy_a = EnemyEntityRef.new("swarm_1", 30, 100, 5)
	enemy_a.grid_position = Vector2i(3, 0)
	
	# Enemy B: Created tick 50 (Older!), HP 30
	var enemy_b = EnemyEntityRef.new("swarm_2", 30, 50, 5)
	enemy_b.grid_position = Vector2i(0, 4)
	
	# Enemy C: Created tick 50 (Same age as B), HP 20 (Lower Health!)
	var enemy_c = EnemyEntityRef.new("swarm_3", 20, 50, 5)
	enemy_c.grid_position = Vector2i(-2, -2)
	
	var swarm: Array[EnemyEntity] = [enemy_a, enemy_b, enemy_c]
	
	# First shot: Should target C (Same age as B, but lower HP)
	turret.tick(swarm)
	assert(enemy_c.health.current_health == 10, "Turret failed to target lowest HP among oldest enemies.")
	assert(enemy_b.health.current_health == 30, "Turret dealt damage to wrong target.")
	assert(enemy_a.health.current_health == 30, "Turret dealt damage to wrong target.")
	
	# Fast forward cooldown
	turret._cooldown = 0
	
	# Manually kill C to test next priority
	enemy_c.health.current_health = 0
	
	# Second shot: Should target B (Older than A)
	var active_swarm: Array[EnemyEntity] = [enemy_a, enemy_b]
	turret.tick(active_swarm)
	
	assert(enemy_b.health.current_health == 20, "Turret failed to prioritize age (creation_tick).")
	assert(enemy_a.health.current_health == 30, "Turret dealt damage to younger target.")

func _test_fire_rate_cooldown() -> void:
	var turret = TurretEntityRef.new("turret_t1", 5, 10)
	turret.grid_position = Vector2i(0, 0)
	turret.fire_rate_ticks = 3 # Takes 3 ticks to reload
	
	var enemy = EnemyEntityRef.new("swarm_1", 50, 1, 5)
	enemy.grid_position = Vector2i(1, 0)
	
	var swarm: Array[EnemyEntity] = [enemy]
	
	# Tick 1: Fires
	turret.tick(swarm)
	assert(enemy.health.current_health == 40, "Turret failed to fire on Tick 1.")
	
	# Tick 2: Cooldown active (Remaining: 2)
	turret.tick(swarm)
	assert(enemy.health.current_health == 40, "Turret fired while on cooldown (Tick 2)!")
	
	# Tick 3: Cooldown active (Remaining: 1)
	turret.tick(swarm)
	assert(enemy.health.current_health == 40, "Turret fired while on cooldown (Tick 3)!")
	
	# Tick 4: Cooldown active (Remaining: 0)
	turret.tick(swarm)
	assert(enemy.health.current_health == 40, "Turret fired while on cooldown (Tick 4)!")
	
	# Tick 5: Ready to fire again!
	turret.tick(swarm)
	assert(enemy.health.current_health == 30, "Turret failed to fire after cooldown elapsed.")