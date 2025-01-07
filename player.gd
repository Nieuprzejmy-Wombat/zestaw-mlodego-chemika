extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const LOOKAROUND_SPEED = 0.01

var raw_ijk := Vector3(1, 0, 0)
var ijk: Vector3
var raw_w : float
var quat: Quaternion
var final_rotation: Quaternion
var is_rotating := false

func update_quat():
	if raw_ijk.length() > 0:
		ijk = raw_ijk.normalized()
	quat = Quaternion(ijk, deg_to_rad(raw_w))
	quaternion = Quaternion(Vector3.FORWARD, ijk)

func _on_rotate_pressed():
	if is_rotating:
		quaternion = final_rotation
	is_rotating = true
	final_rotation = (quat * quaternion).normalized()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	#if is_rotating:
		#var interpolated_quat := quaternion.slerp(final_rotation, delta * LOOKAROUND_SPEED)
		#if interpolated_quat.angle_to(quaternion) < 0.00001:
			#is_rotating = false
			#interpolated_quat = final_rotation
		#quaternion = interpolated_quat
	
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
		var goal := Quaternion(Vector3.MODEL_BOTTOM, event.relative.x) * Quaternion(Vector3.MODEL_LEFT, event.relative.y)
		var interpolated_quat := quaternion.slerp(goal, LOOKAROUND_SPEED)
		if interpolated_quat.angle_to(quaternion) > 0.00001:
			quaternion = interpolated_quat
		
		#update_quat()
		#_on_rotate_pressed()
