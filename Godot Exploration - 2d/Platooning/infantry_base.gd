extends CharacterBody2D
class_name InfantryBase

var STRENGTH: int = randi_range(20, 80)
var SPEED: int = 200

@export var TEAM: String = "ALLY"

func get_team() -> String:
	return self.TEAM

func get_strength() -> int:
	return self.STRENGTH
