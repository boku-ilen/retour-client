extends Node

var tooltips_enabled = false

signal display_tooltip # Sent with a boolean for whether to show the tooltip or not


func _ready():
	connect("display_tooltip", self, "_on_display_tooltip")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pc_toggle_tooltip"):
		emit_signal("display_tooltip", !are_tooltips_enabled())


func are_tooltips_enabled():
	return tooltips_enabled


func _on_display_tooltip(should_display):
	tooltips_enabled = should_display
