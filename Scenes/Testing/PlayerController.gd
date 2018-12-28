extends KinematicBody

var origin_offset_x = int(0)
var origin_offset_z = int(0)

var mouse_sensitivity = 0.1
var camera_angle = 0
var velocity = Vector3()

var FLY_SPEED = 10000

onready var head = get_node("Head")
onready var camera = head.get_node("Camera")

# To prevent floating point errors, the player.translation does not reflect the player's actual position in the whole world.
# This function returns the true world position of the player in int.
func get_true_position():
	return [int(translation.x) - origin_offset_x, int(translation.z) - origin_offset_z]

# Shift the player's in-engine translation by a certain offset, but not the player's true coordinates.
func shift(delta):
	origin_offset_x += int(delta.x)
	origin_offset_z += int(delta.z)
	
	translation.x += delta.x
	translation.z += delta.z

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	fly(delta)

func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		
		var change = -event.relative.y * mouse_sensitivity
		
		if change + camera_angle < 90 and change + camera_angle > -90:
			camera.rotate_x(deg2rad(change))
			camera_angle += change
			
func fly(delta):
	# reset the direction of the player
	var direction = Vector3()
	
	# get the rotation of the camera
	var aim = camera.get_global_transform().basis
	
	# check input and change direction
	if Input.is_action_pressed("ui_up"):
		direction -= aim.z
	if Input.is_action_pressed("ui_down"):
		direction += aim.z
	if Input.is_action_pressed("ui_left"):
		direction -= aim.x
	if Input.is_action_pressed("ui_right"):
		direction += aim.x
	
	direction = direction.normalized()
	
	if Input.is_action_pressed("ui_sprint"):
		direction /= 100
	
	# where would the player go at max speed
	var target = direction * FLY_SPEED
	
	# move
	translation += target * delta