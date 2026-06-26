class_name TurretEntity
extends GridEntity

var targeting: CombatComponents.TargetingComponent
var damage: int = 10
var fire_rate_ticks: int = 5
var _cooldown: int = 0

func _init(p_id: String, p_range: int, p_damage: int) -> void:
	super._init(p_id, Vector2i.ONE)
	targeting = CombatComponents.TargetingComponent.new(p_range)
	damage = p_damage

func tick(all_enemies: Array) -> void:
	if _cooldown > 0:
		_cooldown -= 1
		return
		
	var target = targeting.get_best_target(grid_position, all_enemies)
	if target:
		target.health.take_damage(damage)
		_cooldown = fire_rate_ticks