extends Node
signal tick_started(tick_number: int)
signal tick_completed(tick_number: int)

enum Mode {
	REALTIME,
	MANUAL,
}

enum TickSpeed {
	X1,
    X2,
    X3,
    X4,
    X5
}

const TICK_INTERVAL_SEC: float = 0.1

var speed_multiplier: float = 1.0

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

func resume() -> void:
	_is_running = true

func stop() -> void:
	_is_running = false

func set_speed(speed: TickSpeed) -> void:
	match speed:
		TickSpeed.X1:
			speed_multiplier = 1.0			
		TickSpeed.X2:
			speed_multiplier = 2.0
		TickSpeed.X3:
			speed_multiplier = 3.0
		TickSpeed.X4:
			speed_multiplier = 4.0
		TickSpeed.X5:
			speed_multiplier = 5.0

func get_tick_interval() -> float:

	return TICK_INTERVAL_SEC / speed_multiplier

func _process(delta):

	if _is_running == false:return

	if _mode == Mode.MANUAL:
		return

	_accumulator += delta

	var tick_interval = get_tick_interval()

	while _accumulator >= tick_interval:

		_accumulator -= tick_interval

		_execute_tick()


func _execute_tick() -> void:

	_current_tick += 1

	tick_started.emit(_current_tick)

	for callable in _subscribers:
		if callable.is_valid():
			callable.call(_current_tick)

    # subscribers here
	tick_completed.emit(_current_tick)

func _on_speed_1x_pressed():

	TickScheduler.set_speed(TickSpeed.X1)


func _on_speed_2x_pressed():
	
	TickScheduler.set_speed(TickSpeed.X2)



func _on_speed_3x_pressed():

	TickScheduler.set_speed(TickSpeed.X3)


func _on_speed_4x_pressed():

	TickScheduler.set_speed(TickSpeed.X4)


func _on_speed_5x_pressed():

	TickScheduler.set_speed(TickSpeed.X5)

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

func manual_tick() -> void:
	if _mode == Mode.MANUAL:
		_execute_tick()

func get_current_tick() -> int:
	return _current_tick