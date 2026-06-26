class_name RadialMenu
extends Control

## A categorized popup menu that spawns buttons in a circle around the mouse.

signal item_selected(entity_id: String)
signal menu_closed

@export var radius: float = 120.0
@export var button_size: Vector2 = Vector2(64, 64)

var is_open: bool = false
var _active_buttons: Array[Button] = []

func _ready() -> void:
	# Ensure this UI element doesn't block mouse clicks when invisible
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

## Opens the menu at the specified screen coordinates with a list of entity IDs.
func open(screen_pos: Vector2, available_items: Array[String]) -> void:
	global_position = screen_pos
	is_open = true
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	_clear_buttons()
	
	var item_count = available_items.size()
	if item_count == 0:
		return
		
	var angle_step: float = TAU / item_count
	
	for i in range(item_count):
		var item_id = available_items[i]
		var btn = Button.new()
		
		# In a polished state, this would map to an icon texture based on item_id
		btn.text = item_id 
		btn.custom_minimum_size = button_size
		
		var current_angle = i * angle_step
		var offset_vector = Vector2.from_angle(current_angle) * radius
		
		add_child(btn)
		
		# Center the button precisely on the offset coordinate
		btn.position = offset_vector - (button_size / 2.0)
		
		# Bind the button press to emit our selection signal
		btn.pressed.connect(_on_button_pressed.bind(item_id))
		_active_buttons.append(btn)

func close() -> void:
	is_open = false
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_closed.emit()
	_clear_buttons()

func _clear_buttons() -> void:
	for btn in _active_buttons:
		btn.queue_free()
	_active_buttons.clear()

func _on_button_pressed(item_id: String) -> void:
	item_selected.emit(item_id)
	close()