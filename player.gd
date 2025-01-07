extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const LOOKAROUND_SPEED = 1

var goal := quaternion

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var interpolated_quat := quaternion.slerp(goal, delta * LOOKAROUND_SPEED)
	if interpolated_quat.angle_to(quaternion) > 0.00001:
		quaternion = interpolated_quat
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# TODO: replace UI actions with custom gameplay actions
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	

func _input(event):
	if event is InputEventMouseMotion and event.button_mask & 1:
		goal = Quaternion(Vector3.MODEL_LEFT, event.relative.y) * Quaternion(Vector3.MODEL_BOTTOM, event.relative.x)
		goal = goal.normalized()
	else:
		goal = quaternion # stop moving without input
