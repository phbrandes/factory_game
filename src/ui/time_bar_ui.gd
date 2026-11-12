extends Control

@onready var time_label: Label = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/TimeLabel")
@onready var day_progress_bar: ProgressBar = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/DayProgressBar")
@onready var pausebutton: Button = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/pausebutton")
@onready var playbutton: Button = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/playbutton")
@onready var x2button: Button = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/2xbutton")
@onready var x3button: Button = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/x3button")
@onready var x4button: Button = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/x4button")

enum TickSpeed {
	# The speed levels for the time bar, corresponding to the TickScheduler's speed settings.
	PAUSED = 0,
	X1 = 1,
	X2 = 2,
	X3 = 3,
	X4 = 4,
}

func _start() -> void:
	# Start the TickScheduler in real-time mode.
	TickScheduler.start(TickScheduler.Mode.REALTIME)

func _ready() -> void:
	# Connect to the TickScheduler's tick signal to update the time label and bar on each tick.
	if not TickScheduler.tick_started.is_connected(_on_tick):
		TickScheduler.tick_started.connect(_on_tick)
	_connect_buttons()
	_update_clock()
	_update_button_states()

func _connect_buttons() -> void:
	if pausebutton and not pausebutton.pressed.is_connected(_on_pausebutton_pressed):
		pausebutton.pressed.connect(_on_pausebutton_pressed)
	if playbutton and not playbutton.pressed.is_connected(_on_playbutton_pressed):
		playbutton.pressed.connect(_on_playbutton_pressed)
	if x2button and not x2button.pressed.is_connected(_on_2xbutton_pressed):
		x2button.pressed.connect(_on_2xbutton_pressed)
	if x3button and not x3button.pressed.is_connected(_on_x3button_pressed):
		x3button.pressed.connect(_on_x3button_pressed)
	if x4button and not x4button.pressed.is_connected(_on_x4button_pressed):
		x4button.pressed.connect(_on_x4button_pressed)

func _on_time_label_gui_input() -> String:
	# Returns a string representation of the current time in the format "HH:MM".
	var current_minutes: int = GlobalClock.get_current_minute()
	var current_hours: int = GlobalClock.get_current_hour()
	_update_clock()
	return "%02d:%02d" % [current_hours, current_minutes]

func _on_tick(_tick: int) -> void:
	# Update the time label and progress bar on each tick.
	_update_clock()

func _update_clock() -> void:
	# Update the time label with the current day and time string from the GlobalClock.
	if time_label:
		time_label.text = (
			"Sol %d • %s"
			% [
				GlobalClock.get_current_day(),
				GlobalClock.get_time_string()
			]
		)
	if day_progress_bar:
		day_progress_bar.min_value = 0.0
		day_progress_bar.max_value = 1.0
		day_progress_bar.value = GlobalClock.get_day_progress()

func _update_button_states() -> void:
	var current_speed: TickScheduler.Speed = TickScheduler.get_speed()
	if pausebutton:
		pausebutton.button_pressed = (current_speed == TickScheduler.Speed.PAUSED)
	if playbutton:
		playbutton.button_pressed = (current_speed == TickScheduler.Speed.X1)
	if x2button:
		x2button.button_pressed = (current_speed == TickScheduler.Speed.X2)
	if x3button:
		x3button.button_pressed = (current_speed == TickScheduler.Speed.X3)
	if x4button:
		x4button.button_pressed = (current_speed == TickScheduler.Speed.X4)

func _on_playbutton_pressed() -> void:
	if TickScheduler.paused:
		TickScheduler.resume()
	TickScheduler.set_speed(TickScheduler.Speed.X1)
	_update_button_states()

func _on_pausebutton_pressed() -> void:
	# Pause the TickScheduler when the pause button is pressed.
	TickScheduler.pause()
	_update_button_states()

func _on_2xbutton_pressed() -> void:
	# Set the TickScheduler speed to 2x.
	if TickScheduler.get_speed() != TickScheduler.Speed.X2:
		TickScheduler.set_speed(TickScheduler.Speed.X2)
	_update_button_states()

func _on_x3button_pressed() -> void:
	# Set the TickScheduler speed to 3x.
	if TickScheduler.get_speed() != TickScheduler.Speed.X3:
		TickScheduler.set_speed(TickScheduler.Speed.X3)
	_update_button_states()

func _on_x4button_pressed() -> void:
	# Set the TickScheduler speed to 4x.
	if TickScheduler.get_speed() != TickScheduler.Speed.X4:
		TickScheduler.set_speed(TickScheduler.Speed.X4)
	_update_button_states()
