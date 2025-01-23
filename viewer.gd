extends Node3D

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	match $Area3D.get_overlapping_bodies():
		[var a]:
			var map = get_tree().get_first_node_in_group("Map")
			map.get_child(0).position = a.map_position
			map.visible = true
