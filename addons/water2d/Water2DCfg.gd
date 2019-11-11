tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("Water2D", "Sprite", preload("Water2D.gd"), preload("water_icon.png"))

func _exit_tree():
	remove_custom_type("Water2D")
