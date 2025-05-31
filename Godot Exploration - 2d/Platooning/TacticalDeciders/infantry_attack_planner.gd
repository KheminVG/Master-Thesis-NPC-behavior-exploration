extends Node2D
class_name InfantryAttackPlanner

signal fight
signal new_destination(pos: Vector2)

var target = null
@onready var behavior: StateChart = $Behavior


func _ready() -> void:
	pass


# Callable to connect to EnemyTracker's enemy_position_changed signal
func _on_enemy_tracker_enemy_position_changed(pos: Vector2) -> void:
	self.target = pos
	self.new_destination.emit(self.target)


#-----------------------------------------------------------------------------#
# Idle State

# Callable to connect to InfantryStrategy's attack signal
func _on_strategy_attack() -> void:
	self.behavior.send_event("attack")


# Callable to connect to any signal that wants to halt the attack planner, 
# such as an explore signal or a regroup signal.
func _stop_attack_planner() -> void:
	self.behavior.send_event("stop")


#-----------------------------------------------------------------------------#
# FollowEnemy State
func _on_follow_enemy_state_processing(delta: float) -> void:
	#self.aim_at.emit(self.target)
	pass


#-----------------------------------------------------------------------------#
# Ready State
func _on_fight_taken() -> void:
	self.fight.emit()


# Callable to connect to Infantry Vision's ready_to_fight signal
func _on_ready_to_fight() -> void:
	self.behavior.send_event("ready_to_fight")
