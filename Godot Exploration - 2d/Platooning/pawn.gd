extends InfantryBase
class_name Pawn

signal waypoint_reached
signal clear_pathfinding
signal send_map(message: Dictionary)
signal attack
signal explore
signal regroup

var target_waypoint: Vector2
var _map_initialized: bool = false
@export var nav_margin: float = 15.0
@export var share_map: bool = false

@onready var behavior: StateChart = $Behavior
@onready var communicator: Communicator = $Communicator
@onready var enemy_tracker: EnemyTracker = $EnemyTracker
@onready var explore_planner: ExplorePlanner = $ExplorePlanner
@onready var group_planner: GroupPlanner = $GroupPlanner
@onready var infantry_attack_planner: InfantryAttackPlanner = $InfantryAttackPlanner
@onready var infantry_strategy: InfantryStrategy = $InfantryStrategy
@onready var obstacle_map: ObstacleMap = $ObstacleMap
@onready var pathfinder: Pathfinder = $Pathfinder
@onready var vision: Vision = $Vision


func _ready() -> void:
	# Propagate the team and strength to the vision component. Vision component can compare these to other units.
	self.vision.set_team(self.TEAM)
	self.vision.set_strength(self.STRENGTH)
	
	# Connecting all signals between components of the infantry soldier -------#
	
	self.clear_pathfinding.connect(self.pathfinder._on_clear_pathfinding)
	self.waypoint_reached.connect(self.pathfinder._on_waypoint_reached)
	
	self.explore_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.explore_planner.request_exploration_target.connect(self.obstacle_map._on_explore_planner_request_exploration_target)
	
	self.group_planner.clear_pathfinding.connect(self.pathfinder._on_clear_pathfinding)
	self.group_planner.new_destination.connect(self.pathfinder._on_new_destination)
	
	self.infantry_attack_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.infantry_attack_planner.fight.connect(self._on_fight)
	
	self.attack.connect(self.explore_planner._stop_explore_planner)
	self.attack.connect(self.group_planner._stop_group_planner)
	self.attack.connect(self.infantry_attack_planner._on_strategy_attack)
	self.explore.connect(self.explore_planner._on_strategy_explore)
	self.explore.connect(self.group_planner._stop_group_planner)
	self.explore.connect(self.infantry_attack_planner._stop_attack_planner)
	self.regroup.connect(self.explore_planner._stop_explore_planner)
	self.regroup.connect(self.group_planner._on_strategy_regroup)
	self.regroup.connect(self.infantry_attack_planner._stop_attack_planner)
	
	self.obstacle_map.send_exploration_target.connect(self.explore_planner._on_obstacle_map_send_exploration_target)
	self.obstacle_map.send_path.connect(self.pathfinder._on_obstacle_map_send_path)
	self.obstacle_map.update_done.connect(self.vision._on_obstacle_map_update_done)
	
	self.pathfinder.destination_reached.connect(self.explore_planner._on_pathfinder_destination_reached)
	self.pathfinder.new_waypoint.connect(self._on_pathfinder_new_waypoint)
	self.pathfinder.request_path.connect(self.obstacle_map._on_pathfinder_request_path)
	
	self.vision.enemy_sighted.connect(self.enemy_tracker._on_enemy_sighted)
	self.vision.enemy_lost.connect(self.enemy_tracker._on_enemy_lost)
	self.vision.obstacles_sighted.connect(self.obstacle_map._on_obstacle_sighted)
	self.vision.ready_to_fight.connect(self.infantry_attack_planner._on_ready_to_fight)
	self.vision.ready_to_fight.connect(self._on_ready_to_fight)
	
	self.send_map.connect(self.communicator.data_channel._add_outgoing)
	
	self.communicator.command_channel.attack.connect(self._on_communicator_attack)
	self.communicator.command_channel.explore.connect(self._on_communicator_explore)
	self.communicator.command_channel.regroup.connect(self._on_communicator_regroup)
	
	#--------------------------------------------------------------------------#


func dies() -> void:
	# TODO do some more before removing the agent from the scene.
	# Add information to collector, make sure this agent is not referenced by others
	self.queue_free()


func target_waypoint_reached() -> bool:
	var x_dif = abs(self.global_position.x - self.target_waypoint.x)
	var y_dif = abs(self.global_position.y - self.target_waypoint.y)
	
	if x_dif <= self.nav_margin and y_dif <= self.nav_margin:
		return true
	
	return false


func target_blocked() -> bool:
	var target_tile = self.obstacle_map.grid.global_to_tile(self.target_waypoint)
	if self.obstacle_map.grid.get_tile(target_tile).val == 1:
		return true
	return false


# Callable to connect to Pathfinder's new_waypoint signal
func _on_pathfinder_new_waypoint(waypoint: Vector2) -> void:
	self.target_waypoint = waypoint
	self.behavior.send_event("new_waypoint")


# Callable to connect to Vision's ready_to_fight signal
func _on_ready_to_fight() -> void:
	self.clear_pathfinding.emit()
	self.behavior.send_event("stop")


func _on_fight() -> void:
	var enemy_strength = self.vision.check_enemy_strength()
	if enemy_strength >= self.get_strength():
		# Lose fight resulting in the death of this agent
		self.dies()
	else:
		self.vision.kill()

func _on_share_map_timeout() -> void:
	if self.share_map:
		var message = {
			"channel": "data",
			"tag": "map",
			"data": self.obstacle_map.grid
		}
		self.send_map.emit(message)


func _on_map_receive(map: Grid2D) -> void:
	self.obstacle_map.compare_map(map)


#-----------------------------------------------------------------------------#
# RotateBody State
func _on_rotate_body_state_processing(delta: float) -> void:
	var target_direction = self.global_position.direction_to(self.target_waypoint)
	self.global_rotation = lerp_angle(self.global_rotation, target_direction.angle(), delta * 10)
	
	if self.vision.target_in_front(self.target_waypoint):
		self.behavior.send_event("move")


#-----------------------------------------------------------------------------#
# Moving State
func _on_moving_state_physics_processing(delta: float) -> void:
	if self.target_waypoint_reached():
		self.behavior.send_event("waypoint_reached")
		return
	
	if self.target_blocked():
		self.clear_pathfinding.emit()
		self.behavior.send_event("waypoint_reached")
		return
	
	var target_direction = self.global_position.direction_to(self.target_waypoint)
	self.velocity = target_direction * self.SPEED
	
	var motion = self.velocity * delta
	self.move_and_collide(motion)


func _on_waypoint_reached_taken() -> void:
	self.waypoint_reached.emit()


func _on_infantry_movement_state_entered() -> void:
	if not self._map_initialized:
		var world: PlatoonTestInstance = self.get_parent()
		var dimensions = world.get_map_dimensions()
		self.obstacle_map.build_empty_map(dimensions)
		self._map_initialized = true

#-----------------------------------------------------------------------------#
# Communicator Responses
func _on_communicator_attack(target: Vector2) -> void:
	self.infantry_attack_planner._on_enemy_tracker_enemy_position_changed(target)
	self.attack.emit()


func _on_communicator_explore() -> void:
	self.explore.emit()


func _on_communicator_regroup(pos: Vector2) -> void:
	self.group_planner.set_regroup_point(pos)
	self.regroup.emit()
