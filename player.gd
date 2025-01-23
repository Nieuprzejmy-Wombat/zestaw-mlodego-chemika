extends CharacterBody3D

@export var recipes: Array[Recipe]

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const LOOKAROUND_SPEED = 0.01
const LOOKAROUND_ACCELERATION = 2
const LEVELING_SPEED = 5

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("strafe_left", "strafe_right", "forwards", "backwards")
	var direction = ($Camera3D.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	$Camera3D.rotation.z = lerpf($Camera3D.rotation.z,0,delta*LEVELING_SPEED)

func _input(event):
	var captured := Input.mouse_mode==Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured:
		var rot := Quaternion(
			Vector3.FORWARD,
			Vector3(
				event.relative.x * LOOKAROUND_SPEED * LOOKAROUND_ACCELERATION,
				-event.relative.y * LOOKAROUND_SPEED * LOOKAROUND_ACCELERATION,
				-LOOKAROUND_ACCELERATION
				).normalized()
			).normalized()
		$Camera3D.quaternion = ($Camera3D.quaternion * rot).normalized()
	if event.is_action("hit"):
		if captured:
			pass
		else:
			pass
	if event.is_action("place"):
		if captured:
			pass
		else:
			pass
