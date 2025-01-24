extends Node3D

const DIST := 100

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
			save.position.y -= 0.5 # spawn new material under the collision shape so body_entered won't fire again
			save.rotation = Quaternion.IDENTITY
			world.spawn_material(save)
	iterations = new
