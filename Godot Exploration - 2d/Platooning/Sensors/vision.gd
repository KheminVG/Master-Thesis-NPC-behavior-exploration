extends Node2D
class_name Vision

signal danger
signal enemy_sighted(enemy_position: Vector2)
signal enemy_lost
signal obstacles_sighted(data: Dictionary, ray_origin: Vector2)
signal ready_to_fight

# TODO use the check range to make infantry check the strength of the enemy.
# If the difference is to great: flee
# else: continue attack == do nothing else here

@export var _range: int = 300
@export var _check_range: int = 200
@export var _fighting_range: int = 100
@onready var behavior: StateChart = $Behavior
@onready var vision_cone: Node2D = $VisionCone
@onready var ray_front: RayCast2D = $VisionCone/ray_front

var _team: String = ""
var _strength: int = 0


func set_team(team_name: String) -> void:
	self._team = team_name


func set_strength(strength: int) -> void:
	self._strength = strength


func kill() -> void:
	for ray: RayCast2D in vision_cone.get_children():
		if ray.is_colliding() and ray.get_collider() is InfantryBase and ray.get_collider().get_team() != self._team:
			ray.get_collider().dies()


func enemy_in_front() -> bool:
	if ray_front.is_colliding() and ray_front.get_collider() is InfantryBase and ray_front.get_collider().get_team() != self._team:
		return true
	return false


func enemy_present() -> bool:
	for ray: RayCast2D in vision_cone.get_children():
		if ray.is_colliding() and ray.get_collider() is InfantryBase and ray.get_collider().get_team() != self._team:
			return true
	return false


func check_enemy_strength() -> int:
	for ray: RayCast2D in vision_cone.get_children():
		if ray.is_colliding() and ray.get_collider() is InfantryBase and ray.get_collider().get_team() != self._team:
			return ray.get_collider().get_strength()
	return -1


func get_enemy_position():
	var enemy_collisions: Array[Vector2] = []
	for ray: RayCast2D in vision_cone.get_children():
		if ray.is_colliding() and ray.get_collider() is InfantryBase and ray.get_collider().get_team() != self._team:
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


func get_obstacles() -> Dictionary:
	var data: Dictionary = {}
	var collisions: Array[Vector2] = []
	var normals: Array[Vector2] = []
	for ray: RayCast2D in vision_cone.get_children():
		if ray.is_colliding():
			# Colliders that are not the environment are ignored as obstacles.
			if ray.get_collider() is not TileMapLayer:
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
	
		if self.enemy_distance() <= self._check_range and self.enemy_distance() > self._fighting_range:
			var enemy_strength = self.check_enemy_strength()
			
			if enemy_strength > 0 and enemy_strength > self._strength and abs(enemy_strength - self._strength) >= 30:
				self.danger.emit()
		
		if self.enemy_distance() <= self._fighting_range:
			self.ready_to_fight.emit()


func _on_enemy_lost_taken() -> void:
	self.enemy_lost.emit()


#-----------------------------------------------------------------------------#
# Checking State
func _on_processing_taken() -> void:
	var data = self.get_obstacles()
	self.obstacles_sighted.emit(data, self.global_position)


#-----------------------------------------------------------------------------#
# Waiting State

# Callable to connect to ObstacleMap's update_done signal.
func _on_obstacle_map_update_done() -> void:
	self.behavior.send_event("done")
