extends Node2D
class_name Radar

signal enemy_sighted(enemy_position: Vector2)
signal enemy_lost
signal obstacles_sighted(data: Dictionary, ray_origin: Vector2)

@export var _range: int = 300
@onready var behavior: StateChart = $Behavior
@onready var vision: Node2D = $Vision
@onready var ray_front: RayCast2D = $Vision/ray_front


func enemy_in_front() -> bool:
	if ray_front.is_colliding() and ray_front.get_collider() is TankBody:
		return true
	return false


func enemy_present() -> bool:
	for ray: RayCast2D in vision.get_children():
		if ray.is_colliding() and ray.get_collider() is TankBody:
			return true
	return false


func get_enemy_position():
	var enemy_collisions: Array[Vector2] = []
	for ray: RayCast2D in vision.get_children():
		if ray.is_colliding() and ray.get_collider() is TankBody:
			var collision = ray.get_collision_point()
			enemy_collisions.append(collision)
	
	if not enemy_collisions.is_empty():
		var average_collision = Vector2.ZERO
		for point in enemy_collisions:
			average_collision += point
		average_collision /= enemy_collisions.size()
		return average_collision
	
	return null


func enemy_distance() -> float:
	var enemy_position = self.get_enemy_position()
	return self.global_position.distance_to(enemy_position)


func obstacle_present() -> bool:
	for ray: RayCast2D in vision.get_children():
		if ray.is_colliding() and not ray.get_collider() is TankBody:
			return true
	return false


func get_obstacles() -> Dictionary:
	var data: Dictionary = {}
	var collisions: Array[Vector2] = []
	var normals: Array[Vector2] = []
	for ray: RayCast2D in vision.get_children():
		if ray.is_colliding():
			# Other Tanks are ignored as obstacles.
			if ray.get_collider() is TankBody:
				continue
		
			var collision = ray.get_collision_point()
			var normal = ray.get_collision_normal()
		
			collisions.append(collision)
			normals.append(normal)
		else:
			collisions.append(to_global(ray.target_position))
			normals.append(Vector2.ZERO)
	data["collisions"] = collisions
	data["normals"] = normals
	return data


func target_in_front(target: Vector2) -> bool:
	var direction = self.global_position.direction_to(target)
	var angle_diff = angle_difference(direction.angle(), self.global_rotation)
	if abs(angle_diff) <= 0.02:
		return true
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


func _on_enemy_lost_taken() -> void:
	self.enemy_lost.emit()


#-----------------------------------------------------------------------------#
# Checking State
func _on_checking_state_processing(delta: float) -> void:
	pass


func _on_processing_taken() -> void:
	var data = self.get_obstacles()
	self.obstacles_sighted.emit(data, self.global_position)


#-----------------------------------------------------------------------------#
# Waiting State

# Callable to connect to ObstacleMap's update_done signal.
func _on_obstacle_map_update_done() -> void:
	self.behavior.send_event("done")
