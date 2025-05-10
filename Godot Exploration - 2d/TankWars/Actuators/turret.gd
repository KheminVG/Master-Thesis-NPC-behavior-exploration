extends Node2D
class_name Turret

signal ready_to_shoot

var _radius: float = 18.0
var _range: int = 150
var target = null
@onready var behavior: StateChart = $Behavior
@onready var radar: Radar = $Radar


func _draw() -> void:
	self.draw_circle(Vector2(0.0, 0.0), self._radius, Color.BLACK)
	self.draw_rect(Rect2(0.0, -8.0, 48.0, 16.0), Color.BLACK)


# Callable to connect to AttackPlanner's aim_at signal
func _on_attack_planner_aim_at(enemy_position: Vector2) -> void:
	self.target = enemy_position
	self.behavior.send_event("aim_at")


#-----------------------------------------------------------------------------#
# Aiming State
func _on_aiming_state_processing(delta: float) -> void:
	if self.target != null:
		var target_direction = self.global_position.direction_to(self.target)
		self.rotation = lerp_angle(self.rotation, target_direction.angle(), delta * 20)
		
		var q = radar.enemy_in_front()
		if q:
			pass
		var target_distance = self.global_position.distance_to(self.target)
		if radar.enemy_in_front() and target_distance <= self._range:
			self.behavior.send_event("turret_in_range")


func _on_turret_in_range_taken() -> void:
	self.ready_to_shoot.emit()
