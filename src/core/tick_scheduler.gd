extends Node

signal tick_started(tick_number: int)
signal tick_completed(tick_number: int)

enum Mode {
	REALTIME,
	MANUAL,
}

enum Speed {
	PAUSED = 0,
	X1 = 1,
	X2 = 2,
	X3 = 3,
	X4 = 4,
}

const TICK_INTERVAL_SEC: float = 0.1

var _current_tick: int = 0
var _accumulator: float = 0.0
var _is_running: bool = false
var _mode: Mode = Mode.REALTIME
var _speed: Speed = Speed.X1
var _subscribers: Array[Callable] = []

var paused: bool:
	get:
		return not _is_running or _speed == Speed.PAUSED

func _ready() -> void:
	process_priority = -100

func start(mode: Mode = Mode.REALTIME) -> void:
	_mode = mode
	_is_running = true
	if _speed == Speed.PAUSED:
		_speed = Speed.X1

func pause() -> void:
	_is_running = false

func resume() -> void:
	_is_running = true
	if _speed == Speed.PAUSED:
		_speed = Speed.X1

func set_speed(new_speed: Speed) -> void:
	if new_speed == Speed.PAUSED:
		pause()
		_speed = Speed.PAUSED
	else:
		_speed = new_speed
		_is_running = true

func get_speed() -> Speed:
	if not _is_running:
		return Speed.PAUSED
	return _speed

func reset() -> void:
	_is_running = false
	_current_tick = 0
	_accumulator = 0.0
	_speed = Speed.X1
	_subscribers.clear()

func register_subscriber(callable: Callable) -> void:
	if not _subscribers.has(callable):
		_subscribers.append(callable)

func unregister_subscriber(callable: Callable) -> void:
	var index: int = _subscribers.find(callable)
	if index != -1:
		_subscribers.remove_at(index)

func _process(delta: float) -> void:
	if not _is_running or _mode == Mode.MANUAL or _speed == Speed.PAUSED:
		return

	_accumulator += delta * float(_speed)
	while _accumulator >= TICK_INTERVAL_SEC:
		_accumulator -= TICK_INTERVAL_SEC
		_execute_tick()

func manual_tick() -> void:
	if _mode == Mode.MANUAL:
		_execute_tick()

func _execute_tick() -> void:
	_current_tick += 1
	tick_started.emit(_current_tick)

	for callable in _subscribers:
		if callable.is_valid():
			callable.call(_current_tick)

	tick_completed.emit(_current_tick)

func get_current_tick() -> int:
	return _current_tick
