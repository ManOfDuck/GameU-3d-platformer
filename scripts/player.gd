class_name Player extends CharacterBody3D

signal coin_collected


@export var movement_speed = 250
@export var accel_time_seconds = 1
@export var jump_strength = 7
@export var jump_count = 2

var target_movement_velocity: Vector3
var rotation_direction: float
var gravity = 0

var previously_floored = false

@export var jumps_remaining = 0
var jump_single = true
var jump_double = true

var coins = 0

@onready var particles_trail = $ParticlesTrail
@onready var sound_footsteps = $SoundFootsteps
@onready var model = $Character
@onready var animation = $Character/AnimationPlayer
@onready var view: Node3D = %View

# _physics_process() will be run by Godot over and over again. 
# "delta" is how long it's been since the last time the function was run.
func _physics_process(delta):
	# Calculate how we should move on this frame
	handle_walking(delta)
	
	if is_on_floor():
		# Reset jumps remaining when on floor
		jumps_remaining = jump_count
	else:
		# Apply gravity, found by the built-in get_gravity() function
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("jump") and jumps_remaining > 0:
		jumps_remaining -= 1
		jump()
	
	# This godot function tells the player to move based on the velocity we set above. It handles stuff like collisions for us!
	move_and_slide()
	
	# Rotate the direction we're moving
	if Vector2(velocity.z, velocity.x).length() > 0:
		rotation_direction = Vector2(velocity.z, velocity.x).angle()
	rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10)
	
	# If our y position is too low, tell Godot to restart the level (the current scene)
	if position.y < -10:
		get_tree().reload_current_scene()
	
	# Move our model towards its default scale
	model.scale = model.scale.lerp(Vector3(1, 1, 1), delta * 10)
	
	# If we just landed, squish our model a bit!
	if is_on_floor() and !previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		Audio.play("res://sounds/land.ogg")
	
	previously_floored = is_on_floor()
	
	# Do some fun visual stuff
	handle_effects(delta)


# Handle movement input
func handle_walking(delta):
	# This creates an "arrow" (Vector3) called "input" and tells Godot to read the player's input
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	
	# This is a little weird, it rotates the "arrow" to face the direction of the camera
	# We do this so that pressing Up/W makes you walk away from the camera, not always to the north.
	input = input.rotated(Vector3.UP, view.rotation.y)
	input = input.normalized()
	
	# Calculate how fast we want to be going
	target_movement_velocity = input * movement_speed * delta
	
	print(velocity.x)
	if velocity.x == target_movement_velocity.x and target_movement_velocity.x != 0:
		print("AHAHAH")
	
	# Accelarate towards that value
	velocity.x = lerp(velocity.x, target_movement_velocity.x, 10/accel_time_seconds * delta)
	velocity.z = lerp(velocity.z, target_movement_velocity.z, 10/accel_time_seconds * delta)


# Handle animation(s)
func handle_effects(delta):
	particles_trail.emitting = false
	sound_footsteps.stream_paused = true
	
	if is_on_floor():
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		var speed_factor = horizontal_velocity.length() / movement_speed / delta
		if speed_factor > 0.05:
			if animation.current_animation != "walk":
				animation.play("walk", 0.1)
			
			if speed_factor > 0.3:
				sound_footsteps.stream_paused = false
				sound_footsteps.pitch_scale = speed_factor
			
			if speed_factor > 0.75:
				particles_trail.emitting = true
		
		elif animation.current_animation != "idle":
			animation.play("idle", 0.1)
			
		if animation.current_animation == "walk":
			animation.speed_scale = speed_factor
		else:
			animation.speed_scale = 1.0
			
	elif animation.current_animation != "jump":
		animation.play("jump", 0.1)


# Jumping
func jump():
	Audio.play("res://sounds/jump.ogg")
	model.scale = Vector3(0.5, 1.5, 0.5)
	velocity.y = jump_strength

# Collecting coins
func collect_coin():
	coins += 1
	coin_collected.emit(coins)
