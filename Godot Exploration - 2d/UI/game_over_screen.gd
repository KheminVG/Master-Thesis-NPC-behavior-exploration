# This code is borrowed from work by Joshua Moelans
# https://github.com/JoshuaMoelans/Master-Thesis-Godot-exploration (accessed March 2025)
# Originally developed for his master's thesis at the University of Antwerp

extends CanvasLayer

@onready var title = $PanelContainer/MarginContainer/Rows/Title
@onready var anim_player = $AnimationPlayer
@onready var panel = $PanelContainer
func _ready():
	panel.hide()
	anim_player.play("fade")

func set_title(win: bool):
	if win:
		title.text = "YOU WIN"
		title.modulate = Color.WEB_GREEN;
	else:
		title.text = "YOU LOSE"
		title.modulate = Color.FIREBRICK;

func _on_quit_button_pressed():
	get_tree().quit()


func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")
