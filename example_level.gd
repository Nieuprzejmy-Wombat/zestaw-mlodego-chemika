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
	var chunk := FluidChunkSave.new()
	chunk.position = Vector3i(0, 0, 0)
	chunk.data.resize(16*16*16*16*10)
	chunk.data.fill(0)
	$FluidSim.reset_chunks(Array([chunk], TYPE_OBJECT,"Resource", FluidChunkSave))
