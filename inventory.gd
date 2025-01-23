extends Area3D
class_name Inventory

@export var save: InventorySave = InventorySave.new()

func _ready() -> void:
	body_entered.connect(enter_item)

func enter_item(item: RigidBody3D) -> void:
	save.contained.append(item.save)
	item.queue_free()
