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
	data.fill(0)
	for i in [0]:
		# color
		data[i] = 256
		data[i+1] = 0
		data[i+2] = 0
		
		# position
		data[i+3] = randf()-0.5
		data[i+4] = randf()-0.5
		data[i+5] = randf()-0.5
		
		#velocity
		data[i+6] = 0
		data[i+7] = 0
		data[i+8] = 0
		
		# density
		data[i+9] = 1
	for i in range(10, len(data), 10):
		# color
		data[i] = 0
		data[i+1] = 0
		data[i+2] = 256
		
		# position
		data[i+3] = randf()-0.5
		data[i+4] = randf()-0.5
		data[i+5] = randf()-0.5
		
		#velocity
		data[i+6] = 0
		data[i+7] = -0.5
		data[i+8] = 0
		
		# density
		data[i+9] = 1 if randf()<0.1 else 0
	for i in 10:
		print(data[i])
	$FluidVolume.reset.call_deferred(data)
