extends Area2D
class_name TankBody

signal rotated

var target: Vector2 = self.global_position + Vector2(1.0, 0.0)
@onready var radar: Radar = $Radar
@onready var behavior: StateChart = $Behavior


func _draw() -> void:
	self.draw_rect(Rect2(-30.0, -20.0, 60.0, 40.0), Color.DARK_GREEN)


# Callable to connect to Tank's travel_target signal
func _on_tank_travel_target(pos: Vector2):
	self.target = pos
	self.behavior.send_event("rotate")


#-----------------------------------------------------------------------------#
# Rotating State
func _on_rotating_state_processing(delta: float) -> void:
	var target_direction = self.global_position.direction_to(target)
	self.global_rotation = lerp_angle(self.global_rotation, target_direction.angle(), delta * 10)
	
	if self.radar.target_in_front(self.target):
		self.behavior.send_event("rotated")


func _on_rotated_taken() -> void:
	self.rotated.emit()
