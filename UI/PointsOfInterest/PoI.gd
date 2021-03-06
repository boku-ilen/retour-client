extends HBoxContainer

#
# This script handles the UI-Element of the points of interest.
#

# All the ui elements for the PoI UI functionality
onready var parent_button = get_parent()
onready var input_field = get_node("VBoxContainer/TextEdit")
onready var save_button = get_node("VBoxContainer/Save")
onready var item_list = get_node("VBoxContainer/ItemList")
onready var add_button = get_node("VBoxContainer/HBoxContainer/Add")
onready var delete_button = get_node("VBoxContainer/HBoxContainer/Delete")
onready var arrow_up = get_node("Arrows/ArrowUp")
onready var arrow_down = get_node("Arrows/ArrowDown")

var pos_manager: PositionManager


func _ready():
	add_button.connect("pressed", self, "_on_add_pressed")
	save_button.connect("pressed", self, "_on_save_pressed")
	delete_button.connect("pressed", self, "_on_delete_pressed")
	arrow_up.connect("pressed", self, "_on_arrow_up")
	arrow_down.connect("pressed", self, "_on_arrow_down")
	
	# FIXME: Load POIs from GeoPackage
	#_load_pois()
	
	item_list.add_item("actual coordinates")
	item_list.set_item_metadata(0, [422699, 450292])
	
	item_list.add_item("0,0 coordinates")
	item_list.set_item_metadata(1, [0, 0])


# FIXME: Adapt to GeoPackage
func _load_pois():
	var pois = null
	
	var index = 0
	# create a Point of Interest for each entry in the locations
	for poi in pois:
		var text = poi.get_attribute("id")
		item_list.add_item(text)
		# Create a vector for the locations data (only contains "x" and "z"-axis)
		# As the coordinates from the server are responded in a different type we have to use a "-" on the x-axis
		var fixed_pos = [-poi.get_vector3().x, -poi.get_vector3().z]
		
		# The ID in the list is not necessarily the same as the id in the json-file thus we have to
		# set the poi-id in the metadata
		item_list.set_item_metadata(index, fixed_pos)
		
		index += 1


# Points of interest UI functionality
func _on_add_pressed():
	input_field.visible = true
	save_button.visible = true


func _on_save_pressed():
	# Create an array for the locations data (only contains "x" and "z"-axis)
	# FIXME: Get the player position here
	var fixed_pos = [0, 0]
	
	# Search for bad url characters
	var regex = RegEx.new()
	regex.compile(".*[!@#$%^&*(),.?\"\/\\\\:{}|<>].*")
	var has_bad_chars = regex.search(input_field.text)
	
	if has_bad_chars:
		logger.warning("New PoI name must not contain special characters")
		input_field.set_text("No special characters!")
		return
	
	# To escape whitespaces use ``.percent_encode()``
	var url_escaped_input = input_field.text.percent_encode()
	
	# As the coordinates on the server are responded in a different type,
	# we have to use a "-" on the x-axis to properly save it
	#FIXME: we have to decide how we want to provide this functionallity after
	#FIXME: the locations come from a (should be readonly) geopackage
	var result = "" # ServerConnection.get_json("/location/create/%s/%d.0/%d.0/%d" % [url_escaped_input, -fixed_pos[0], fixed_pos[1], Session.scenario_id], false)
	
	# Only store on client if it was also successfully stored on server
	if result.creation_success:
		item_list.add_item(input_field.text)
		# The item will be added as the last element in the list
		item_list.set_item_metadata(item_list.get_item_count() - 1, fixed_pos)
	
	input_field.set_text("")
	input_field.visible = false
	save_button.visible = false


func _on_delete_pressed():
	# select mode is set to single, so only one item can be selected
	var current_item : int = item_list.get_selected_items()[0]
	var item_text : String = item_list.get_item_text(current_item)

	#FIXME: we have to decide how we want to provide this functionallity after
	#FIXME: the locations come from a (should be readonly) geopackage
	var result = "" # ServerConnection.get_json("/location/remove/%s/%d" % [item_text, Session.scenario_id], false)
	
	# Only store on client if it was also successfully stored on server
	if result.removal_success:
		item_list.remove_item(current_item)


func _on_arrow_up():
	# FIXME: this crashes the landscapelab if the POI list is empty
	var current_item : int = item_list.get_selected_items()[0]
	var item_text : String = item_list.get_item_text(current_item)
	
	#var result = ServerConnection.get_json("/location/increase_order/%s/%d" % [item_text, Session.scenario_id], false)
	
	item_list.move_item(current_item, current_item - 1)


func _on_arrow_down():
	# FIXME: this crashes the landscapelab if the POI list is empty
	var current_item : int = item_list.get_selected_items()[0]
	var item_text : String = item_list.get_item_text(current_item)
	
	#var result = ServerConnection.get_json("/location/increase_order/%s/%d" % [item_text, Session.scenario_id], false)
	
	item_list.move_item(current_item, current_item + 1)
