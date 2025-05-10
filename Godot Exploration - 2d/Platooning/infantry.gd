extends CharacterBody2D
class_name Infantry

signal waypoint_reached
signal clear_pathfinding

var SPEED: int = 200
var target_waypoint: Vector2
var _map_initialized: bool = false
@export var nav_margin: float = 15.0

@onready var behavior: StateChart = $Behavior
@onready var obstacle_map: ObstacleMap = $ObstacleMap
@onready var radar: Radar = $Radar
@onready var explore_planner: ExplorePlanner = $ExplorePlanner
@onready var pathfinder: Pathfinder = $Pathfinder
@onready var infantry_strategy: InfantryStrategy = $InfantryStrategy

func _ready() -> void:
	# Connecting all signals between components of the tank ------------------#
	
	self.radar.obstacles_sighted.connect(self.obstacle_map._on_radar_obstacle_sighted)
	self.pathfinder.request_path.connect(self.obstacle_map._on_pathfinder_request_path)
	self.explore_planner.request_exploration_target.connect(self.obstacle_map._on_explore_planner_request_exploration_target)
	
	self.obstacle_map.update_done.connect(self.radar._on_obstacle_map_update_done)
	
	self.pathfinder.destination_reached.connect(self.explore_planner._on_pathfinder_destination_reached)
	self.obstacle_map.send_exploration_target.connect(self.explore_planner._on_obstacle_map_send_exploration_target)
	self.infantry_strategy.explore.connect(self.explore_planner._on_strategy_explore)
	
	self.explore_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.waypoint_reached.connect(self.pathfinder._on_waypoint_reached)
	self.obstacle_map.send_path.connect(self.pathfinder._on_obstacle_map_send_path)
	self.clear_pathfinding.connect(self.pathfinder._on_clear_pathfinding)
	
	self.pathfinder.new_waypoint.connect(self._on_pathfinder_new_waypoint)
	
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
func _on_rotate_body_state_processing(delta: float) -> void:
	var target_direction = self.global_position.direction_to(self.target_waypoint)
	self.global_rotation = lerp_angle(self.global_rotation, target_direction.angle(), delta * 10)
	
	if self.radar.target_in_front(self.target_waypoint):
		self.behavior.send_event("move")


#-----------------------------------------------------------------------------#
# Moving State
func _on_moving_state_physics_processing(delta: float) -> void:
	if self.target_waypoint_reached():
		self.behavior.send_event("waypoint_reached")
		return
	
	var target_direction = self.global_position.direction_to(self.target_waypoint)
	self.velocity = target_direction * self.SPEED
	
	var motion = self.velocity * delta
	self.move_and_collide(motion)


func _on_waypoint_reached_taken() -> void:
	self.waypoint_reached.emit()


func _on_infantry_movement_state_entered() -> void:
	if not self._map_initialized and self.get_parent():
		# Initialize the empty ObstacleMap by getting the dimensions from the world.
		var world: TankWarsInstance = self.get_parent()
		var dimensions = world.get_map_dimensions()
		self.obstacle_map.build_empty_map(dimensions)
		self._map_initialized = true
