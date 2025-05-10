extends Node2D
class_name InfantryStrategy

#signal attack
signal explore
@onready var behavior: StateChart = $Behavior

# TODO further enhance the infantry strategy.


#-----------------------------------------------------------------------------#
# Explore State
func _on_exploring_state_entered() -> void:
	self.explore.emit()


## Callable to connect to EnemyTracker's enemy_position_known signal
#func _on_enemy_tracker_enemy_position_known() -> void:
	#self.behavior.send_event("attack")


##-----------------------------------------------------------------------------#
## Attack State
#func _on_attacking_state_entered() -> void:
	#self.attack.emit()
#
#
##Callable to connect to EnemyTracker's enemy_position_unsure signal
#func _on_enemy_tracker_enemy_position_unsure() -> void:
	#self.behavior.send_event("enemy_lost")
#
#
##-----------------------------------------------------------------------------#
