extends Node2D
class_name EnemyTracker

signal enemy_position_known
signal enemy_position_changed(pos: Vector2)
signal enemy_position_unsure

var tracked_position = null
@export var enemy_margin: float = 64.0
@onready var behavior: StateChart = $Behavior

# TODO implement
## Check if given new position differs significantly from the current tracked 
## position. If so, the tracked position is updated and true is returned.
func enemy_moved(new_position) -> bool:
	if self.tracked_position == null:
		self.tracked_position = new_position
		return true
	
	var x_dif = abs(self.tracked_position.x - new_position.x)
	var y_dif = abs(self.tracked_position.y - new_position.y)
	
	if x_dif <= self.enemy_margin and y_dif <= self.enemy_margin:
		return false
	
	self.tracked_position = new_position
	return true

func get_enemy_position():
	return self.tracked_position

# Callable to connect to any Radar's enemy_sighted signals.
func _on_enemy_sighted(enemy_position) -> void:
	self.behavior.send_event("enemy_sighted")
	if self.enemy_moved(enemy_position):
		self.behavior.send_event("enemy_moved")
		self.enemy_position_changed.emit(self.get_enemy_position())


# Callable to connect to any Radar's enemy_lost signals.
func _on_enemy_lost() -> void:
	self.behavior.send_event("enemy_lost")

#-----------------------------------------------------------------------------#
# EnemyPosKnown State
func _on_enemy_pos_known_state_entered() -> void:
	self.enemy_position_known.emit()

#-----------------------------------------------------------------------------#
# EnemyPosUnsure State
func _on_enemy_pos_unsure_state_entered() -> void:
	self.enemy_position_unsure.emit()
