extends AbstractPlayer

#
# This scene handles a basic first person controller with a flying mode
# and a walking mode.
#

var origin_offset_x : int = 0
var origin_offset_z : int = 0

var mouse_sensitivity = Settings.get_setting("player", "mouse-sensitivity")
var camera_angle = 0
var velocity = Vector3()
var dragging : bool = false
var rotating : bool = false
var _vr_mode : bool = false

var walking = Settings.get_setting("player", "start-walking-enabled")

var FLY_SPEED = Settings.get_setting("player", "fly-speed")
var SPRINT_SPEED = Settings.get_setting("player", "fly-speed-sprint")
var SNEAK_SPEED = Settings.get_setting("player", "fly-speed-sneak")

onready var head = get_node("Head")
onready var camera = head.get_node("Camera")


func _ready():
	GlobalSignal.connect("vr_enable", self, "_set_vr_mode", [true])
	GlobalSignal.connect("vr_disable", self, "_set_vr_mode", [false])


# To prevent floating point errors, the player.translation does not reflect the player's 
# actual position in the whole world. This function returns the true world position of 
# the player (in webmercator meters) as integers.
func get_true_position():
	return Offset.to_world_coordinates(translation)


func get_look_direction():
	# TODO: The x-coordinate seems right, but the z-coordinate acts strangely...
	return camera.global_transform.basis.x	


func _physics_process(delta):
	
	# only change position if vr_mode is disabled
	if not _vr_mode:
		fly(delta)
		PlayerInfo.update_player_look_direction(get_look_direction())


func _unhandled_input(event):
	# TODO: input could be generalized in AbstractPlayer?
	
	# only accept input if vr mode is disabled
	if not _vr_mode:
		# Check if the mouse is over the viewport
		if get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position()):
			if event is InputEventMouseButton:
				get_tree().set_input_as_handled()
				
				if event.button_index == BUTTON_LEFT: 
					if event.pressed:
						dragging = true
					else:
						dragging = false
				elif event.button_index == BUTTON_RIGHT:
					if event.pressed:
						rotating = true
					else: 
						rotating = false
			
			# Rotate the camera if the event is mouse motion and the mouse is currently captured or right mouse button is pressed
			if event is InputEventMouseMotion and (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED or rotating):
				get_tree().set_input_as_handled()
				
				head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
				
				var change = -event.relative.y * mouse_sensitivity
				
				if change + camera_angle < 90 and change + camera_angle > -90:
					camera.rotate_x(deg2rad(change))
					camera_angle += change
					
			elif event.is_action_pressed("pc_toggle_walk"):
				walking = not walking
	

func fly(delta):
	# reset the direction of the player
	var direction = Vector3()
	
	# get the rotation of the camera
	var aim = camera.get_global_transform().basis
	
	# check input and change direction
	if Input.is_action_pressed("pc_move_up"):
		direction -= aim.z
		has_moved = true
	if Input.is_action_pressed("pc_move_down"):
		direction += aim.z
		has_moved = true
	if Input.is_action_pressed("pc_move_left"):
		direction -= aim.x
		has_moved = true
	if Input.is_action_pressed("pc_move_right"):
		direction += aim.x
		has_moved = true
	
	direction = direction.normalized()
	
	if Input.is_action_pressed("ui_sprint"):
		direction *= SPRINT_SPEED / FLY_SPEED
	elif Input.is_action_pressed("ui_sneak"):
		direction *= SNEAK_SPEED / FLY_SPEED
	
	# where would the player go at max speed
	var target
	
	if walking:
		target = direction * PlayerInfo.walk_speed
	else:
		target = direction * FLY_SPEED
	
	# move
	move_and_slide(target)
	
	if walking:
		translation = WorldPosition.get_position_on_ground(translation)


func switch_follow_mode():
	PlayerInfo.update_player_pos(translation)
	PlayerInfo.is_follow_enabled = !PlayerInfo.is_follow_enabled


func _set_vr_mode(vr_mode):
	logger.info("vr mode set to %s " % [vr_mode])
	_vr_mode = vr_mode
