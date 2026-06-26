class_name EnemyEntity
extends GridEntity

var health: CombatComponents.HealthComponent
var creation_tick: int
var speed_ticks: int = 10
var _ticks_since_move: int = 0

func _init(p_id: String, hp: int, p_creation_tick: int, p_speed_ticks: int = 10) -> void:
	super._init(p_id, Vector2i.ONE)
	health = CombatComponents.HealthComponent.new(hp)
	creation_tick = p_creation_tick
	speed_ticks = p_speed_ticks

func tick(flow_field: FlowField) -> void:
	_ticks_since_move += 1
	if _ticks_since_move >= speed_ticks:
		var dir = flow_field.get_direction(grid_position)
		grid_position += dir
		_ticks_since_move = 0