extends Control



func _on_btn_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nivel_0.tscn")


func _on_btn_salir_pressed() -> void:
	get_tree().quit()
