extends Control

# State Variables
var ore: int = 8
var power: int = 15
var state: String = "IDLE"
var cycle: int = 0
var output: int = 0
var generator_on: bool = false

# Constants limits
const MAX_ORE = 10
const MAX_POWER = 20
const MAX_CYCLE = 4
const MAX_OUTPUT = 10

# UI Colors
const COLOR_EMPTY = Color(0.2, 0.2, 0.25)
const COLOR_ORE = Color(0.35, 0.65, 1.0)
const COLOR_POWER = Color(0.45, 0.85, 0.45)
const COLOR_IDLE = Color(0.4, 0.4, 0.4)
const COLOR_PROCESSING = Color(0.8, 0.8, 0.8)

@onready var log_console = %LogConsole

func _ready():
	# Procedurally generate the UI segmented bars
	_generate_bars(%InputBars, MAX_ORE)
	_generate_bars(%EnergyBars, MAX_POWER)
	_generate_bars(%ProcessBars, MAX_CYCLE)
	_generate_bars(%OutputGrid, MAX_OUTPUT)

	# Link buttons to logic
	%AdvanceBtn.pressed.connect(_on_advance)
	%InsertBtn.pressed.connect(_on_insert)
	%GeneratorToggle.toggled.connect(_on_generator_toggled)

	log_console.scroll_following = true
	log_message("System online. Press 'Advance Tick' to start.")
	update_ui()

func _generate_bars(container: Control, amount: int):
	for i in range(amount):
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(24, 24)
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(rect)

func update_ui():
	# Update colors of segmented blocks
	_color_blocks(%InputBars, ore, COLOR_ORE)
	_color_blocks(%EnergyBars, power, COLOR_POWER)
	_color_blocks(%ProcessBars, cycle, COLOR_PROCESSING if state == "PROCESSING" else COLOR_IDLE)
	_color_blocks(%OutputGrid, output, COLOR_IDLE)

	# Update panel labels
	%InputLabel.text = "%d / %d units" % [ore, MAX_ORE]
	%EnergyLabel.text = "%d / %d EU" % [power, MAX_POWER]
	%StateBadge.text = "%"
	%ProcessLabel.text = "Cycle Progress: %d/%d" % [cycle, MAX_CYCLE]

	# Update bottom summary values
	%SummaryOre.text = "Ore\n%d/%d" % [ore, MAX_ORE]
	%SummaryPower.text = "Power\n%d/%d" % [power, MAX_POWER]
	%SummaryState.text = "State\n%s" % state
	%SummaryOutput.text = "Output\n%d" % output

func _color_blocks(container: Control, active_amount: int, active_color: Color):
	var blocks = container.get_children()
	for i in range(blocks.size()):
		blocks[i].color = active_color if i < active_amount else COLOR_EMPTY

func log_message(msg: String):
	log_console.text += msg + "\n"

func _on_reset():
	ore = 8
	power = 15
	state = "IDLE"
	cycle = 0
	output = 0
	generator_on = false
	%GeneratorToggle.button_pressed = false
	log_console.text = ""
	log_message("System reset.")
	update_ui()

func _on_advance():
	if generator_on:
		power = min(power + 2, MAX_POWER)
		log_message("+2 EU from generator.")

	if state == "IDLE":
		if ore > 0 and power >= 1:
			state = "PROCESSING"
			ore -= 1
			log_message("Started processing 1 ore.")
		elif ore == 0:
			log_message("Idle: Insufficient ore.")
	elif state == "PROCESSING":
		if power >= 2:
			power -= 2
			cycle += 1
			if cycle >= MAX_CYCLE:
				cycle = 0
				state = "IDLE"
				output = min(output + 1, MAX_OUTPUT)
				log_message("Processing complete. 1 refined bar produced.")
		else:
			log_message("Processing halted: Insufficient power.")

	update_ui()

func _on_insert():
	if ore < MAX_ORE:
		ore = min(ore + 2, MAX_ORE)
		log_message("Inserted ore manually.")
		update_ui()
	else:
		log_message("Input buffer is full.")

func _on_generator_toggled(toggled_on: bool):
	generator_on = toggled_on
	log_message("Generator " + ("connected." if generator_on else "disconnected."))
