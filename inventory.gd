extends Area3D
class_name Inventory

@export var save: InventorySave = InventorySave.new()
@export var volume: float = INF

func _ready() -> void:
	body_entered.connect(enter_item)

func enter_item(item: RigidBody3D) -> void:
	var volume_left := volume
	for i in save.contained:
		volume_left -= i.shape.size.x*i.shape.size.y*i.shape.size.z
	print(volume_left)
	if volume_left >= item.save.shape.size.x*item.save.shape.size.y*item.save.shape.size.z:
		save.contained.append(item.save)
		item.queue_free()
	else:
		var defered_func := func ():
			enter_item(item)
		get_tree().create_timer(0.1).timeout.connect(defered_func)
