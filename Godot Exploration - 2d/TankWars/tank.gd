extends CharacterBody2D
class_name Steering

signal travel_target(target: Vector2)
signal waypoint_reached


var SPEED: int = 300
var target_waypoint: Vector2
@export var nav_margin: float = 30.0

@onready var behavior: StateChart = $Behavior

@onready var tank_body: TankBody = $TankBody
@onready var turret: Turret = $Turret

@onready var enemy_tracker: EnemyTracker = $EnemyTracker
@onready var obstacle_map: ObstacleMap = $ObstacleMap

@onready var attack_planner: AttackPlanner = $AttackPlanner
@onready var explore_planner: ExplorePlanner = $ExplorePlanner
@onready var pathfinder: Pathfinder = $Pathfinder


func _ready() -> void:
	# Connecting all signals between components of the tank ------------------#
	
	self.travel_target.connect(self.tank_body._on_tank_travel_target)
	
	self.attack_planner.aim_at.connect(self.turret._on_attack_planner_aim_at)
	
	self.tank_body.radar.enemy_sighted.connect(self.enemy_tracker._on_radar_enemy_sighted)
	self.tank_body.radar.enemy_lost.connect(self.enemy_tracker._on_radar_enemy_lost)
	self.turret.radar.enemy_sighted.connect(self.enemy_tracker._on_radar_enemy_sighted)
	self.turret.radar.enemy_lost.connect(self.enemy_tracker._on_radar_enemy_lost)
	
	self.tank_body.radar.obstacles_sighted.connect(self.obstacle_map._on_radar_obstacle_sighted)
	self.turret.radar.obstacles_sighted.connect(self.obstacle_map._on_radar_obstacle_sighted)
	self.pathfinder.request_path.connect(self.obstacle_map._on_pathfinder_request_path)
	self.explore_planner.request_exploration_target.connect(self.obstacle_map._on_explore_planner_request_exploration_target)
	
	self.turret.ready_to_shoot.connect(self.attack_planner._on_turret_ready_to_shoot)
	
	self.pathfinder.destination_reached.connect(self.explore_planner._on_pathfinder_destination_reached)
	self.obstacle_map.send_exploration_target.connect(self.explore_planner._on_obstacle_map_send_exploration_target)
	
	self.attack_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.explore_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.tank_body.radar.obstacles_sighted.connect(self.pathfinder._on_tank_body_radar_obstacle_sighted)
	self.waypoint_reached.connect(self.pathfinder._on_tank_waypoint_reached)
	self.obstacle_map.send_path.connect(self.pathfinder._on_obstacle_map_send_path)
	
	#-------------------------------------------------------------------------#

func target_waypoint_reached() -> bool:
	var x_dif = abs(self.global_position.x - self.target_waypoint.x)
	var y_dif = abs(self.global_position.y - self.target_waypoint.y)
	
	if x_dif <= self.nav_margin and y_dif <= self.nav_margin:
		return true
	
	return false


# Callable to connect to Pathfinder's new_waypoint signal
func _on_pathfinder_new_waypoint(waypoint: Vector2) -> void:
	self.target_waypoint = waypoint
	self.behavior.send_event("new_waypoint")


#-----------------------------------------------------------------------------#
# RotateBody State
func _on_rotate_body_state_entered() -> void:
	self.travel_target.emit(self.target_waypoint)


# Callable to connect to TankBody's rotated signal
func _on_tank_body_rotated() -> void:
	self.behavior.send_event("move")


#-----------------------------------------------------------------------------#
# Moving State
func _on_moving_state_processing(delta: float) -> void:
	if self.target_waypoint_reached():
		self.behavior.send_event("waypoint_reached")
	
	var target_direction = self.global_position.direction_to(self.target_waypoint)
	self.velocity = target_direction * self.SPEED
	
	self.move_and_slide()


func _on_waypoint_reached_taken() -> void:
	self.waypoint_reached.emit()
