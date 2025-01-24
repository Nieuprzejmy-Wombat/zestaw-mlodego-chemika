extends Node3D
class_name GameWorld

@export var rough_solid_shape: Shape3D
@export var rough_solid_mesh: Mesh
@export var solid_shape: Shape3D
@export var solid_mesh: Mesh

@export var albedo_r: MaterialProperty
@export var albedo_g: MaterialProperty
@export var albedo_b: MaterialProperty

@export var state: MaterialProperty
@export var melting_point: float
@export var evaporation_point: float

@export var item_scene: PackedScene

@onready var Fluids = $Fluids

func spawn_material(save: ItemSave):
	var curr_state := state.apply(save.point)
	if curr_state < melting_point:
		var item := item_scene.instantiate()
		item.save = save
		item.position = save.position
		item.quaternion = save.rotation
		add_child(item)
	elif curr_state < evaporation_point:
		var item := item_scene.instantiate()
		item.save = save
		item.position = save.position
		item.quaternion = save.rotation
		item.type = FluidType.FluidType.WATER
		Fluids.spawn(save.position, item)
	else:
		pass # TODO
