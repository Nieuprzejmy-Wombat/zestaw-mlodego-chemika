extends TabContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var file = FileAccess.open("user://.settings", FileAccess.READ)
	if file == null:
		file = FileAccess.open("res://.settings", FileAccess.READ)
	var settings = file.get_var()
	for elem in get_tab_control(current_tab).get_children():
		if elem.is_in_group("setting"):
			elem.value = settings[elem.name]

func _on_tab_clicked(tab: int) -> void:
	match tab:
		0: # Exit
			$".".visible = false
		1: # Save
			$".".visible = false
			var settings = {}
			for elem in get_tab_control(current_tab).get_children():
				if elem.is_in_group("setting"):
					settings[elem.name] = elem.value
			FileAccess.open("user://.settings", FileAccess.WRITE).store_var(settings)
		2: # Reset
			$".".visible = false
			var settings = FileAccess.open("res://.settings", FileAccess.READ).get_var()
			for elem in get_tab_control(current_tab).get_children():
				if elem.is_in_group("setting"):
					elem.value = settings[elem.name]
