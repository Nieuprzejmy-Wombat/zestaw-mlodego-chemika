extends Control


func _on_button_exit_pressed() -> void:
	get_tree().quit()


func _on_button_settings_pressed() -> void:
	$SettingsMenu.visible = true


func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://example_level.tscn")
