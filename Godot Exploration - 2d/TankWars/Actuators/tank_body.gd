extends Node2D
class_name TankBody

signal rotated

var target: Vector2 = self.global_position + Vector2(1.0, 0.0)
@onready var radar: Radar = $Radar

# Callable to connect to Tank's travel_target signal
func _on_tank_travel_target(position: Vector2):
	self.target = position
	self.behavior.send_event("rotate")


#-----------------------------------------------------------------------------#
# Rotating State
func _on_rotating_state_processing(delta: float) -> void:
	var target_direction = self.global_position.direction_to(target)
	self.rotation = lerp_angle(self.rotation, target_direction.angle(), 0.2)
	
	if self.radar.target_in_front(self.target):
		self.behavior.send_event("rotated")


func _on_rotated_taken() -> void:
	self.rotated.emit()
