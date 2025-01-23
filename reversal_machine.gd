extends Node3D

const DIST := 1000 # TODO: fix: if 100 not spawning properly

@onready var iterations := Time.get_ticks_msec()

@onready var world: GameWorld = get_tree().current_scene

func _process(_delta: float) -> void:
	var new = Time.get_ticks_msec()/DIST
	for i in range(iterations, new):
		if len($Inventory.save.contained)>0:
			var save := ItemSave.new()
			var current = $Inventory.save.contained.pop_back()
			save.point = -current.point
			save.shape = current.shape
			save.position = $Output.global_position
			save.rotation = Quaternion.IDENTITY
			world.spawn_material(save)
	iterations = new
