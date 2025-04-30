extends Node2D
class_name AttackPlanner

const RELOADTIME: float = 4.0
signal shoot
signal new_destination(pos: Vector2)
signal aim_at(target: Vector2)

# TODO figure out when to send the new_destination event
# TODO connect attack and explore signals of the PilotStrategy

@onready var enemy_tracker: EnemyTracker = $EnemyTracker
@onready var behavior: StateChart = $Behavior

func _ready() -> void:
	self.behavior.set_expression_property.call_deferred("reload_time", RELOADTIME)


#-----------------------------------------------------------------------------#
# Idle State
func _on_attack_taken() -> void:
	var target = enemy_tracker.get_enemy_position()
	self.aim_at.emit(target)


# Callable to connect to PilotStrategy's attack signal
func _on_pilot_strategy_attack() -> void:
	self.behavior.send_event("attack")


# Callable to connect to PilotStrategy's explore signal
func _on_pilot_startegy_explore() -> void:
	self.behavior.send_event("explore")


#-----------------------------------------------------------------------------#
# FollowEnemy State
func _on_follow_enemy_state_processing(delta: float) -> void:
	var target = enemy_tracker.get_enemy_position()
	self.aim_at.emit(target)


#-----------------------------------------------------------------------------#
# Ready State
func _on_shoot_taken() -> void:
	self.shoot.emit()


# Callable to connect to Turret's ready_to_shoot signal.
func _on_turret_ready_to_shoot() -> void:
	behavior.send_event("ready_to_shoot")
