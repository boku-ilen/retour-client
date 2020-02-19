extends HBoxContainer


onready var button = get_node("Button")
onready var panel = get_node("PanelContainer")
onready var tween = get_node("Tween")
onready var dropdown = get_node("Control")

onready var panel_pos_x = panel.rect_position.x
var panel_start_pos: Vector2
var _panel_unfolded: bool = false

# TODO: Fix hardcoding for mode, for now we only have mode 0
var all_values: Dictionary = ValuesLoader.get_all_values_for_mode(0)


func _ready():
	button.connect("pressed", self, "_on_button_pressed")
	dropdown.connect("item_selected", self, "_on_value_changed")
	panel.connect("resized", self, "_on_panel_resize")
	
	_fill_dropdown()
	# Load the default selected (index 0) energy-ui
	_on_value_changed(0)
	
	# To have the panel folded in on startup we have to call for the pressed method
	_on_button_pressed()


func _on_button_pressed():
	_panel_unfolded = !_panel_unfolded
	
	if _panel_unfolded:
		_move_panel(panel_start_pos)
		button.set_rotation_degrees(0)
	else:
		_move_panel(Vector2(panel_pos_x, 0))
		button.set_rotation_degrees(180)


func _on_panel_resize():
	panel_start_pos = Vector2(panel_pos_x, panel.rect_size.y - 30)
	if !_panel_unfolded:
		panel.set_position(panel_start_pos)


func _on_value_changed(id: int):
	# Clear any other ui currently loaded
	for child in panel.get_children():
		child.queue_free()
	
	# Load the data from the values-settings.json
	var path_to_scene = all_values[dropdown.get_item_text(id)]
	var value_ui = load(path_to_scene)
	panel.add_child(value_ui.instance())
	
	# As the size of the panel-size changes with another value-ui we have to 
	# adjust the panel so it is not fully shown and can be unfolded via buttonclick
	panel_start_pos = Vector2(panel_pos_x, panel.rect_size.y - 30)
	if !_panel_unfolded:
		panel.set_position(panel_start_pos)


# Animated motion of the panel
func _move_panel(vec_to: Vector2):
	tween.interpolate_property(panel, "rect_position",
		panel.rect_position, vec_to, 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()


func _fill_dropdown():
	# Fill in each label of the values
	for value in all_values:
		dropdown.add_item(value)