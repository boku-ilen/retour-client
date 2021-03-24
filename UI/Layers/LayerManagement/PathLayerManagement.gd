extends AbstractLayerManagement


var edit_cursor = preload("res://Resources/Icons/ModernLandscapeLab/paintbrush.svg")
var edit_action: ActionHandler.Action


func _ready():
	$AddPaths.connect("toggled", self, "_on_edit")


func set_player(player):
	.set_player(player)
	edit_action = EditAction.new(layer, pc_player.action_handler.cursor, pc_player, false)


class EditAction extends ActionHandler.Action:
	var cursor: RayCast
	var layer: Layer
	var path: Path
	
	func _init(l, c, p, blocking).(p, blocking):
		cursor = c
		layer = l
		path = load("res://Street.tscn").instance()
		player.get_parent().add_child(path)
#		var vis = CSGPolygon.new()
#		vis.material = Material.new()
#		path.visualizer = vis
	
	func new_path():
		path = load("res://Street.tscn").instance()
		player.get_parent().get_node("Terrain").add_child(path)
	
	func apply(event: InputEvent):
		if event.is_action_pressed("layer_add_feature"):
			# FIXME: this is far from clean and should be altered once Geodot offers
			# FIXME: a proper feature for writing to a 
			#layer.add_point_feature(PointFeature)
			if path == null: new_path()
			path.curve.add_point(cursor.get_collision_point())
		if event.is_action_pressed("layer_end_feature"):
			# FIXME: Finishing logic ...
			path = null


func _on_edit(toggled):
	if toggled:
		pc_player.action_handler.set_current_action(edit_action, edit_cursor)
	else:
		pc_player.action_handler.stop_current_action()