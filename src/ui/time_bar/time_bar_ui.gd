extends Control

@onready var time_label: Label = $PanelContainer/MarginContainer/HBoxContainer/TimeLabel
@onready var pausebutton: Button = $PanelContainer/MarginContainer/HBoxContainer/pausebutton
@onready var playbutton: Button = $PanelContainer/MarginContainer/HBoxContainer/playbutton

func _ready() -> void:
	TickScheduler.start(TickScheduler.Mode.REALTIME)
	TickScheduler.tick_started.connect(_on_tick)
	_update_clock()

func _on_time_label_gui_input(_event: InputEvent) -> void:
	_update_clock()

func _on_tick(_tick: int) -> void:
	_update_clock()

func _update_clock() -> void:
	time_label.text = "Sol %d • %s" % [
		GlobalClock.get_current_day(),
		GlobalClock.get_time_string()
	]

func _on_playbutton_pressed() -> void:
	if not TickScheduler.is_running():
		TickScheduler.resume()
	TickScheduler.set_speed(TickScheduler.TickSpeed.X1)

func _on_pausebutton_pressed() -> void:
	TickScheduler.pause()

func _on_xbutton_pressed() -> void:
	if not TickScheduler.is_running():
		TickScheduler.resume()
	TickScheduler.set_speed(TickScheduler.TickSpeed.X2)

func _on_x3button_pressed() -> void:
	if not TickScheduler.is_running():
		TickScheduler.resume()
	TickScheduler.set_speed(TickScheduler.TickSpeed.X3)

func _on_x4button_pressed() -> void:
	if not TickScheduler.is_running():
		TickScheduler.resume()
	TickScheduler.set_speed(TickScheduler.TickSpeed.X4)

func _on_5xbutton_pressed() -> void:
	if not TickScheduler.is_running():
		TickScheduler.resume()
	TickScheduler.set_speed(TickScheduler.TickSpeed.X5)
