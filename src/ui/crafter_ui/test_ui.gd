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
const COLOR_EMPTY = Color("#323342")
const COLOR_ORE = Color("#5085ff")
const COLOR_POWER = Color("#78e078")
const COLOR_IDLE = Color("#b0b0b0")
const COLOR_PROCESSING = Color("#8585a0")

@onready var log_console = %LogConsole

func _ready():
	_apply_visual_styles()
	
	# Procedurally generate the UI segmented bars with specific sizes
	_generate_bars(%InputBars, MAX_ORE, Vector2(30, 26))
	_generate_bars(%EnergyBars, MAX_POWER, Vector2(14, 26))
	_generate_bars(%ProcessBars, MAX_CYCLE, Vector2(65, 20))
	_generate_bars(%OutputGrid, MAX_OUTPUT, Vector2(20, 20))

	# Link buttons to logic
	%ResetBtn.pressed.connect(_on_reset)
	%AdvanceBtn.pressed.connect(_on_advance)
	%InsertBtn.pressed.connect(_on_insert)
	%GeneratorToggle.toggled.connect(_on_generator_toggled)

	log_console.scroll_following = true
	log_message("System online. Press 'Advance Tick' to start.")
	update_ui()

# --- NEW: Automatically styles the UI to look like the target image ---
func _apply_visual_styles():
	# 1. Main Background Color
	$ColorRect.color = Color("#111116")
	
	# 2. Panel Styles (Rounded dark boxes with borders)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#242530")
	panel_style.border_color = Color("#434454")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 15
	panel_style.content_margin_top = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_bottom = 15

	for panel in %DashboardGrid.get_children():
		panel.add_theme_stylebox_override("panel", panel_style)

	# 3. Log Console Style
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color("#242530")
	log_style.set_corner_radius_all(6)
	log_style.content_margin_left = 15
	log_style.content_margin_top = 15
	%LogConsole.add_theme_stylebox_override("normal", log_style)

	# 4. Button Styles
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color("#32333d")
	btn_style.set_corner_radius_all(24)
	btn_style.content_margin_top = 12
	btn_style.content_margin_bottom = 12
	%AdvanceBtn.add_theme_stylebox_override("normal", btn_style)
	%InsertBtn.add_theme_stylebox_override("normal", btn_style)
	%AdvanceBtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%InsertBtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Reset Button is smaller and circular
	var reset_style = btn_style.duplicate()
	reset_style.content_margin_left = 15
	reset_style.content_margin_right = 15
	%ResetBtn.add_theme_stylebox_override("normal", reset_style)

	# 5. Block Spacing
	%InputBars.add_theme_constant_override("separation", 4)
	%EnergyBars.add_theme_constant_override("separation", 4)
	%ProcessBars.add_theme_constant_override("separation", 4)
	%OutputGrid.add_theme_constant_override("h_separation", 15)
	%OutputGrid.add_theme_constant_override("v_separation", 10)
	
	# 6. IDLE/PROCESSING Badge Style
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color("#d0d0d0")
	badge_style.set_corner_radius_all(12)
	%LStateBadge.add_theme_stylebox_override("normal", badge_style)
	%LStateBadge.add_theme_color_override("font_color", Color("#111111"))
	%LStateBadge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%LStateBadge.custom_minimum_size = Vector2(80, 24)
	%LStateBadge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

func _generate_bars(container: Control, amount: int, block_size: Vector2):
	for i in range(amount):
		var rect = ColorRect.new()
		rect.custom_minimum_size = block_size
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(rect)

func update_ui():
	# Update colors of segmented blocks
	_color_blocks(%InputBars, ore, COLOR_ORE)
	_color_blocks(%EnergyBars, power, COLOR_POWER)
	_color_blocks(%ProcessBars, cycle, COLOR_PROCESSING if state == "PROCESSING" else COLOR_EMPTY)
	_color_blocks(%OutputGrid, output, COLOR_PROCESSING) # Process color used for output bars

	# Update panel labels
	%InputLabel.text = "%d / %d units" % [ore, MAX_ORE]
	%EnergyLabel.text = "%d / %d EU" % [power, MAX_POWER]
	
	%LStateBadge.text = state
	var badge_style = %LStateBadge.get_theme_stylebox("normal")
	if badge_style:
		badge_style.bg_color = Color("#d0d0d0") if state == "IDLE" else Color("#78e078")
		
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
