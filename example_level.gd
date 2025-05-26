extends GameWorld

func reload_settings():
	var file = FileAccess.open("user://.settings", FileAccess.READ)
	if file == null:
		file = FileAccess.open("res://.settings", FileAccess.READ)
	var settings = file.get_var()
	$Player/Camera3D.fov = settings["Fov"]

func _on_settings_menu_hidden() -> void:
	reload_settings()

func _ready() -> void:
	reload_settings()
	var data := PackedFloat32Array()
	data.resize(10*16*8*8*8*4*2*1)
	data.fill(1)
	for i in range(0, len(data), 10):
		# color
		data[i] = 1
		data[i+1] = 1
		data[i+2] = 255
		
		#velocity
		data[i+6] = 100
		data[i+7] = -1
		data[i+8] = 100
		
		# density
		data[i+9] = randf() * 100 + 1
	$FluidVolume.reset.call_deferred(data)
