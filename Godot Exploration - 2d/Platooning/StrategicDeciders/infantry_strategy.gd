extends Node2D
class_name InfantryStrategy

signal attack
signal explore
signal regroup

@onready var behavior: StateChart = $Behavior


#-----------------------------------------------------------------------------#
# Explore State
func _on_exploring_state_entered() -> void:
	self.explore.emit()


# Callable to connect to EnemyTracker's enemy_position_known signal
func _on_enemy_tracker_enemy_position_known() -> void:
	self.behavior.send_event("attack")


func _on_explore_planner_done() -> void:
	self.behavior.send_event("regroup")


func _on_team_group() -> void:
	self.behavior.send_event("regroup")


func _on_team_explore() -> void:
	self.behavior.send_event("explore")


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
# Grouping State
func _on_grouping_state_entered() -> void:
	self.regroup.emit()


#-----------------------------------------------------------------------------#
# Fleeing State
func _on_fleeing_state_entered() -> void:
	self.regroup.emit()
