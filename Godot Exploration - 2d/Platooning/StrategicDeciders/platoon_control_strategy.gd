extends Node2D
class_name PlatoonControlStrategy

signal explore
@onready var behavior: StateChart = $Behavior


#------------------------------------------------------------------------------#
# Exploring State
func _on_exploring_state_entered() -> void:
	self.explore.emit()
