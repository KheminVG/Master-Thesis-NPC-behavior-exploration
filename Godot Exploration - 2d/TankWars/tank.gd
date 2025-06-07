extends CharacterBody2D
class_name Tank

# TODO further enhance the Tank behavior. Include FUEL, REPAIR, DAMAGE

signal travel_target(waypoint: Vector2)
signal waypoint_reached
signal clear_pathfinding


var SPEED: int = 300
var target_waypoint: Vector2
var _map_initialized: bool = false
@export var nav_margin: float = 15.0

@onready var behavior: StateChart = $Behavior
@onready var moving: AtomicState = $Behavior/TankMovement/Moving

@onready var tank_body: TankBody = $TankBody
@onready var turret: Turret = $Turret

@onready var enemy_tracker: EnemyTracker = $EnemyTracker
@onready var obstacle_map: ObstacleMap = $ObstacleMap

@onready var attack_planner: AttackPlanner = $AttackPlanner
@onready var explore_planner: ExplorePlanner = $ExplorePlanner
@onready var pathfinder: Pathfinder = $Pathfinder

@onready var pilot_strategy: PilotStrategy = $PilotStrategy


func _ready() -> void:
	# Connecting all signals between components of the tank ------------------#
	
	self.obstacle_map.update_done.connect(self.tank_body.radar._on_obstacle_map_update_done)
	self.obstacle_map.update_done.connect(self.turret.radar._on_obstacle_map_update_done)
	
	self.travel_target.connect(self.tank_body._on_tank_travel_target)
	
	self.attack_planner.aim_at.connect(self.turret._on_attack_planner_aim_at)
	
	self.tank_body.radar.enemy_sighted.connect(self.enemy_tracker._on_enemy_sighted)
	self.tank_body.radar.enemy_lost.connect(self.enemy_tracker._on_enemy_lost)
	self.turret.radar.enemy_sighted.connect(self.enemy_tracker._on_enemy_sighted)
	self.turret.radar.enemy_lost.connect(self.enemy_tracker._on_enemy_lost)
	
	self.tank_body.radar.obstacles_sighted.connect(self.obstacle_map._on_obstacle_sighted)
	self.turret.radar.obstacles_sighted.connect(self.obstacle_map._on_obstacle_sighted)
	self.pathfinder.request_path.connect(self.obstacle_map._on_pathfinder_request_path)
	self.explore_planner.request_exploration_target.connect(self.obstacle_map._on_explore_planner_request_exploration_target)
	
	self.turret.ready_to_shoot.connect(self.attack_planner._on_turret_ready_to_shoot)
	self.pilot_strategy.attack.connect(self.attack_planner._on_strategy_attack)
	self.pilot_strategy.explore.connect(self.attack_planner._stop_attack_planner)
	self.enemy_tracker.enemy_position_changed.connect(self.attack_planner._on_enemy_tracker_enemy_position_changed)
	
	self.pathfinder.destination_reached.connect(self.explore_planner._on_pathfinder_destination_reached)
	self.obstacle_map.send_exploration_target.connect(self.explore_planner._on_obstacle_map_send_exploration_target)
	self.pilot_strategy.attack.connect(self.explore_planner._stop_explore_planner)
	self.pilot_strategy.explore.connect(self.explore_planner._on_strategy_explore)
	
	self.attack_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.explore_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.waypoint_reached.connect(self.pathfinder._on_waypoint_reached)
	self.obstacle_map.send_path.connect(self.pathfinder._on_obstacle_map_send_path)
	self.clear_pathfinding.connect(self.pathfinder._on_clear_pathfinding)
	
	self.enemy_tracker.enemy_position_known.connect(self.pilot_strategy._on_enemy_tracker_enemy_position_known)
	self.enemy_tracker.enemy_position_unsure.connect(self.pilot_strategy._on_enemy_tracker_enemy_position_unsure)
	
	self.pathfinder.new_waypoint.connect(self._on_pathfinder_new_waypoint)
	self.tank_body.rotated.connect(self._on_tank_body_rotated)
	self.turret.ready_to_shoot.connect(self._on_turret_ready_to_shoot)
	
	#-------------------------------------------------------------------------#


func target_waypoint_reached() -> bool:
	var x_dif = abs(self.global_position.x - self.target_waypoint.x)
	var y_dif = abs(self.global_position.y - self.target_waypoint.y)
	
	if x_dif <= self.nav_margin and y_dif <= self.nav_margin:
		return true
	
	return false


# Callable to connect to Turret's ready_to_shoot signal.
func _on_turret_ready_to_shoot() -> void:
	self.behavior.send_event("stop")
	self.clear_pathfinding.emit()

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


func _on_tank_movement_state_entered() -> void:
	if not self._map_initialized:
		# Initialize the empty ObstacleMap by getting the dimensions from the world.
		var world: TankWarsInstance = self.get_parent()
		var dimensions = world.get_map_dimensions()
		self.obstacle_map.build_empty_map(dimensions)
		self._map_initialized = true
