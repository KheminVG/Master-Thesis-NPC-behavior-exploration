# This code is borrowed from work by Joshua Moelans
# https://github.com/JoshuaMoelans/Master-Thesis-Godot-exploration (accessed March 2025)
# Originally developed for his master's thesis at the University of Antwerp

extends Node2D

enum TeamName{
	PLAYER,
	ENEMY
}

@export var team:TeamName = TeamName.PLAYER
