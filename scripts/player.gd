class_name Player extends CharacterBody3D

signal coin_collected


@export_subgroup("Properties")
@export var movement_speed = 250
@export var jump_strength = 7

var movement_velocity: Vector3
var rotation_direction: float
var gravity = 0

var previously_floored = false

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
	handle_controls(delta)
	handle_gravity(delta)
	
	# Do some fun visual stuff
	handle_effects(delta)
	
	# Movement
	var applied_velocity: Vector3
	
	# NOTE: movement_velocity was set by the handle_controls() function above
	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	
	# NOTE: gravity was set by the handle_gravity() function above
	applied_velocity.y = -gravity
	
	velocity = applied_velocity
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
	if is_on_floor() and gravity > 2 and !previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		Audio.play("res://sounds/land.ogg")
	
	previously_floored = is_on_floor()

# Handle movement input
func handle_controls(delta):
	# This creates an "arrow" (Vector3) called "input" and tells Godot to read the player's input
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	
	# This is a little weird, it rotates the "arrow" to face the direction of the camera
	# We do this so that pressing Up/W makes you walk away from the camera, not always to the north.
	input = input.rotated(Vector3.UP, view.rotation.y)
	input = input.normalized()
	
	# Update movement_velocity, for use later in physics_process()
	movement_velocity = input * movement_speed * delta
	
	# If the player pressed the jump button and we still have a jump left, call jump()
	if Input.is_action_just_pressed("jump"):
		if jump_single or jump_double:
			jump()


# Handle gravity
func handle_gravity(delta):
	gravity += 25 * delta
	if gravity > 0 and is_on_floor():
		jump_single = true
		gravity = 0


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
	gravity = -jump_strength
	model.scale = Vector3(0.5, 1.5, 0.5)
	
	if jump_single:
		jump_single = false;
		jump_double = true;
	else:
		jump_double = false;

# Collecting coins
func collect_coin():
	coins += 1
	coin_collected.emit(coins)
