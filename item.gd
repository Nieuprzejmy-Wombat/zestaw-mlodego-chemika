extends RigidBody3D
class_name Item

@onready var world: GameWorld = get_tree().current_scene

@export var save: ItemSave:
	get:
		save.position = position
		save.rotation = quaternion
		return save

var rebuild_required := true

func require_rebuild() -> void:
	rebuild_required = true

func _ready() -> void:
	save.changed.connect(require_rebuild)
	require_rebuild()

func _process(_delta: float) -> void:
	if rebuild_required:
		rebuild()
		rebuild_required = false

func rebuild() -> void:
	$CollisionShape3D.shape = world.rough_solid_shape if save.shape.rough else world.solid_shape
	$MeshInstance3D.mesh = world.rough_solid_mesh if save.shape.rough else world.solid_mesh
	$MeshInstance3D.material_override.albedo_color = Color(world.albedo_r.apply(save.point), world.albedo_g.apply(save.point), world.albedo_b.apply(save.point))
