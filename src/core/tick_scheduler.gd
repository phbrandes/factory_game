extends Node

signal tick_started(tick_number: int)
signal tick_completed(tick_number: int)

enum Mode {
	REALTIME,
	MANUAL,
}

const TICK_INTERVAL_SEC: float = 0.1

var _current_tick: int = 0
var _accumulator: float = 0.0
var _is_running: bool = false
var _mode: Mode = Mode.REALTIME
var _subscribers: Array[Callable] = []

func _ready() -> void:
	process_priority = -100

func start(mode: Mode = Mode.REALTIME) -> void:
	_mode = mode
	_is_running = true

func pause() -> void:
	_is_running = false

func reset() -> void:
	_is_running = false
	_current_tick = 0
	_accumulator = 0.0
	_subscribers.clear()

func restore_state(tick_number: int, accumulator: float = 0.0) -> void:
	_current_tick = tick_number
	_accumulator = accumulator

func register_subscriber(callable: Callable) -> void:
	if not _subscribers.has(callable):
		_subscribers.append(callable)

func unregister_subscriber(callable: Callable) -> void:
	var index: int = _subscribers.find(callable)
	if index != -1:
		_subscribers.remove_at(index)

func _process(delta: float) -> void:
	if not _is_running or _mode == Mode.MANUAL:
		return

	_accumulator += delta
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
