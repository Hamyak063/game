extends ColorRect


func _on_Start_button_up():
	Global.game_over = false
	Global.score = 0
	get_tree().change_scene_to_file("res://Game.tscn")


func _on_Exit_button_up():
	get_tree().quit()
