extends Node2D
class_name AttackPlanner

const RELOADTIME: float = 4.0

signal shoot
signal new_destination(pos: Vector2)
signal aim_at(target: Vector2)

# TODO figure out when to send the new_destination event
# TODO connect attack and explore signals of the PilotStrategy

var target = null
@onready var enemy_tracker: EnemyTracker = $EnemyTracker
@onready var behavior: StateChart = $Behavior

func _ready() -> void:
	self.behavior.set_expression_property.call_deferred("reload_time", RELOADTIME)


# Callable to connect to EnemyTracker's enemy_position_changed signal
func _on_enemy_tracker_enemy_position_changed(pos: Vector2) -> void:
	self.target = pos
	self.aim_at.emit(self.target)
	self.new_destination.emit(self.target)


#-----------------------------------------------------------------------------#
# Idle State
func _on_attack_taken() -> void:
	if target != null:
		self.aim_at.emit(self.target)


# Callable to connect to PilotStrategy's attack signal
func _on_strategy_attack() -> void:
	self.behavior.send_event("attack")


# Callable to connect to PilotStrategy's explore signal
func _on_strategy_explore() -> void:
	self.behavior.send_event("explore")


#-----------------------------------------------------------------------------#
# FollowEnemy State
func _on_follow_enemy_state_processing(delta: float) -> void:
	#self.aim_at.emit(self.target)
	pass


#-----------------------------------------------------------------------------#
# Ready State
func _on_shoot_taken() -> void:
	print("BANG")
	self.shoot.emit()


# Callable to connect to Turret's ready_to_shoot signal.
func _on_turret_ready_to_shoot() -> void:
	behavior.send_event("ready_to_shoot")
