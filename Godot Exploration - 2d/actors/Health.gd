# This code is borrowed from work by Joshua Moelans
# https://github.com/JoshuaMoelans/Master-Thesis-Godot-exploration (accessed March 2025)
# Originally developed for his master's thesis at the University of Antwerp

extends Node2D


@export var health:int = 100 : set = set_health, get = get_health

func set_health(h:int) -> void:
	health = clamp(h,0,100)
	
func get_health() -> int:
	return health
