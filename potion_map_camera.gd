extends CharacterBody3D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var movement:=(event as InputEventMouseMotion).relative
		var rot := Quaternion(
			Vector3.FORWARD, Vector3(movement.x,-movement.y,-100).normalized()
			).normalized()
		$Camera3D.quaternion = ($Camera3D.quaternion * rot).normalized()
		# roll is a feature

func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var u = randf()
	var v = randf()
	var w = randf()
	$Camera3D.quaternion=Quaternion(sqrt(1-u)*sin(TAU*v), sqrt(1-u)*cos(TAU*v), sqrt(u)*sin(TAU*w), sqrt(u)*cos(TAU*w))

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
