extends Node2D
class_name Turret

signal ready_to_shoot

var range: int = 150
var target = null
@onready var behavior: StateChart = $Behavior
@onready var radar: Radar = $Radar


# Callable to connect to AttackPlanner's aim_at signal
func _on_attack_planner_aim_at(enemy_position: Vector2) -> void:
	self.target = enemy_position
	self.behavior.send_event("aim_at")


#-----------------------------------------------------------------------------#
# Aiming State
func _on_aiming_state_processing(delta: float) -> void:
	if self.target != null:
		var target_direction = self.global_position.direction_to(target)
		self.rotation = lerp_angle(self.rotation, target_direction.angle(), 0.2)
	
		if radar.enemy_in_front() and radar.enemy_distance() <= self.range:
			self.behavior.send_event("turret_in_range")


func _on_turret_in_range_taken() -> void:
	self.ready_to_shoot.emit()
