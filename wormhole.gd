extends Area3D

@export_node_path("Area3D")
var other

func _on_area_entered(area: Area3D) -> void:
	area.global_position=other.global_position+global_position-area.global_position
	area.collision_layer=2
	get_tree().create_timer(10).timeout.connect(func ():area.collision_layer=1)
