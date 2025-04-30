extends Node2D
class_name EnemyTracker

var tracked_position = null
@onready var behavior: StateChart = $Behavior

# TODO implement
func enemy_moved(new_position) -> bool:
	return false

func get_enemy_position():
	return self.tracked_position

# Callable to connect to any Radar's enemy_sighted signals.
func _on_radar_enemy_sighted(enemy_position) -> void:
	self.behavior.send_event("enemy_sighted")
	self.enemy_moved(enemy_position)


# Callable to connect to any Radar's enemy_lost signals.
func _on_radar_enemy_lost() -> void:
	self.behavior.send_event("enemy_lost")
