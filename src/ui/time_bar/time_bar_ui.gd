extends Control

@onready var time_label: Label = $PanelContainer/MarginContainer/HBoxContainer/TimeLabel
@onready var pausebutton: Button = $PanelContainer/MarginContainer/HBoxContainer/pausebutton
@onready var playbutton: Button = $PanelContainer/MarginContainer/HBoxContainer/playbutton

enum TickSpeed {
	# The speed levels for the time bar, corresponding to the TickScheduler's speed settings.
	X1,
	X2,
	X3,
	X4,
	X5
}
func _start():
	# Start the TickScheduler in real-time mode.
	TickScheduler.start(TickScheduler.Mode.REALTIME)

func _ready():
	# Connect to the TickScheduler's tick signal to update the time label on each tick.
	TickScheduler.tick_started.connect(_on_tick)
	_update_clock()

func _on_time_label_gui_input() -> String:
	# Returns a string representation of the current time in the format "HH:MM".
	var total_minutes = GlobalClock.get_total_minutes()
	var total_hours = GlobalClock.get_total_hours()
	_update_clock()
	return"%d:%" % [total_hours, total_minutes]
	

func _on_tick(_tick):
	# Update the time label on each tick.
	_update_clock()

func _update_clock():
	# Update the time label with the current day and time string from the GlobalClock.
	time_label.text =(
        "Sol %d • %s"
		% [
			GlobalClock.get_current_day(),
			GlobalClock.get_time_string()
		]
	)

func _on_playbutton_pressed():
	if TickScheduler.get_speed() == TickScheduler.paused:
		# Resume the TickScheduler when the play button is pressed.
		TickScheduler.resume()
		TickScheduler.set_speed(TickScheduler.Speed.X1)
	else:
		TickScheduler.set_speed(TickScheduler.Speed.X1)


	# Resume the TickScheduler when the play button is pressed.
	TickScheduler.resume()
	TickScheduler.set_speed(TickScheduler.Speed.X1)

func _on_pausebutton_pressed() -> void:
	# Pause the TickScheduler when the pause button is pressed.
	TickScheduler.pause()

func _on_2xbutton_pressed() -> void:
	# Set the TickScheduler speed to 2x only when the 2x button is not pressed.
	if TickScheduler.get_speed() == TickScheduler.Speed.X2:
		return
	else:
		TickScheduler.set_speed(TickScheduler.Speed.X2)
func _on_x3button_pressed() -> void:
	# Set the TickScheduler speed to 3x only when the 3x button is not pressed.
	if TickScheduler.get_speed() == TickScheduler.Speed.X3:
		return
	else:
		TickScheduler.set_speed(TickScheduler.Speed.X3)


func _on_x4button_pressed() -> void:
	# Set the TickScheduler speed to 4x only when the 4x button is not pressed.
	if TickScheduler.get_speed() == TickScheduler.Speed.X4:
		return
	else:
		TickScheduler.set_speed(TickScheduler.Speed.X4)	
