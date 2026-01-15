extends Node3D

@export_group("Properties")
@export var target: Node

@export_group("Zoom")
@export var zoom_minimum = 16
@export var zoom_maximum = 4
@export var zoom_speed = 10

@export_group("Rotation")
@export var rotation_speed = 120

@export_group("Mouse_settings")
@export var capture_mouse := true
@export var mouse_sens = 0.1

var camera_rotation:Vector3
var zoom = 10

@onready var camera = $Camera

func _ready():
	camera_rotation = rotation_degrees # Initial rotation


func _physics_process(delta):
	# Set position and rotation to target's
	self.position = self.position.lerp(target.position, delta * 4)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)
	
	camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)
	
	handle_joystick_input(delta)

# Joystick input
func handle_joystick_input(delta):
	# Rotation
	var input := Vector3.ZERO
	
	input.y = Input.get_axis("camera_left", "camera_right")
	input.x = Input.get_axis("camera_up", "camera_down")
	
	camera_rotation += input.limit_length(1.0) * rotation_speed * delta
	camera_rotation.x = clamp(camera_rotation.x, -80, -10)
	
	# Zooming
	zoom += Input.get_axis("zoom_in", "zoom_out") * zoom_speed * delta
	zoom = clamp(zoom, zoom_maximum, zoom_minimum)


# Mouse input
func _input(event: InputEvent) -> void:
	# Read mouse input if the mouse is invisible (captured)
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# Apply the motion to the camera's rotation
			var mouse_rotation := Vector3.ZERO
			mouse_rotation.y = -event.screen_relative.x
			mouse_rotation.x = -event.screen_relative.y
			camera_rotation += mouse_rotation * mouse_sens
			camera_rotation.x = clamp(camera_rotation.x, -80, -10)
	
	# If shift is pressed, toggle the mouse mode (shift-lock)
	if Input.is_action_just_pressed("toggle_mouse_capture_mode"):
		capture_mouse = not capture_mouse
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if capture_mouse:
		# When we click, capture the mouse (depending on mouse mode)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		# Set the mouse mode based on if right-click is held (depnding on mouse mode)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.is_action_pressed("rotate_camera_uncaptured") else Input.MOUSE_MODE_VISIBLE
	
	# Free the mouse if escape is pressed in any mode
	if event.is_action_pressed("free_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
