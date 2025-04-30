extends Node2D
class_name Radar

signal enemy_sighted(enemy_position)
signal enemy_lost
signal obstacles_sighted(obstacles)

@export var range: int = 150
@onready var behavior: StateChart = $Behavior

# TODO Implement these functions
func enemy_in_front() -> bool:
	return false

func enemy_present() -> bool:
	return false

func get_enemy_position() -> Vector2:
	return Vector2(0.0, 0.0)

func enemy_distance() -> float:
	return 0.0

func obstacle_present() -> bool:
	return false

func get_obstacles() -> Array[Vector2]:
	return [Vector2i(0, 0)]

func target_in_front(target: Vector2) -> bool:
	return false

#-----------------------------------------------------------------------------#
# NoEnemy State
func _on_no_enemy_state_processing(delta: float) -> void:
	if self.enemy_present():
		self.behavior.send_event("enemy_sighted")


#-----------------------------------------------------------------------------#
# EnemySighted State
func _on_enemy_sighted_state_processing(delta: float) -> void:
	if not self.enemy_present():
		self.behavior.send_event("enemy_lost")
	else:
		var enemy_position = self.get_enemy_position()
		self.enemy_sighted.emit(enemy_position)
	
		#if self.enemy_in_front():
			#self.enemy_aligned.emit()


func _on_enemy_lost_taken() -> void:
	self.enemy_lost.emit()


#-----------------------------------------------------------------------------#
# Checking State
func _on_checking_state_processing(delta: float) -> void:
	if self.obstacle_present():
		self.behavior.send_event("obstacle_sighted")


func _on_obstacle_sighted_taken() -> void:
	var obstacles = self.get_obstacles()
	self.obstacles_sighted.emit(obstacles)
