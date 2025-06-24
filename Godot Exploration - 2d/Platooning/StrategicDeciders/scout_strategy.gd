extends Node2D
class_name ScoutStrategy

signal attack
signal explore
signal new_destination(pos: Vector2)

var safe_point: Vector2 = Vector2(0, 0)
@onready var behavior: StateChart = $Behavior


func set_safe_point(pos: Vector2) -> void:
	self.safe_point = pos


#-----------------------------------------------------------------------------#
# Explore State
func _on_exploring_state_entered() -> void:
	self.explore.emit()


# Callable to connect to EnemyTracker's enemy_position_known signal
func _on_enemy_tracker_enemy_position_known() -> void:
	self.behavior.send_event("attack")


#-----------------------------------------------------------------------------#
# Attack State
func _on_attacking_state_entered() -> void:
	self.attack.emit()


#Callable to connect to EnemyTracker's enemy_position_unsure signal
func _on_enemy_tracker_enemy_position_unsure() -> void:
	self.behavior.send_event("enemy_lost")


#-----------------------------------------------------------------------------#
# NormalOperation State

# Callable to connect to danger signal
func _on_enemy_danger() -> void:
	self.behavior.send_event("flee")


#-----------------------------------------------------------------------------#
# Fleeing State
func _on_fleeing_state_entered() -> void:
	self.new_destination.emit(self.safe_point)
