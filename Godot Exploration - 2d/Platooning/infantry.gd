extends InfantryBase
class_name Infantry

signal waypoint_reached
signal clear_pathfinding
signal share_map(map: Grid2D)

var target_waypoint: Vector2
var _map_initialized: bool = false
@export var nav_margin: float = 15.0

@onready var behavior: StateChart = $Behavior
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
	
	self.enemy_tracker.enemy_position_changed.connect(self.infantry_attack_planner._on_enemy_tracker_enemy_position_changed)
	self.enemy_tracker.enemy_position_known.connect(self.infantry_strategy._on_enemy_tracker_enemy_position_known)
	self.enemy_tracker.enemy_position_unsure.connect(self.infantry_strategy._on_enemy_tracker_enemy_position_unsure)
	
	self.explore_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.explore_planner.request_exploration_target.connect(self.obstacle_map._on_explore_planner_request_exploration_target)
	self.explore_planner.done.connect(self.infantry_strategy._on_explore_planner_done)
	
	self.group_planner.clear_pathfinding.connect(self.pathfinder._on_clear_pathfinding)
	self.group_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.group_planner.reached_regroup.connect(self._share_map_at_regroup_point)
	
	self.infantry_attack_planner.new_destination.connect(self.pathfinder._on_new_destination)
	self.infantry_attack_planner.fight.connect(self._on_fight)
	
	self.infantry_strategy.attack.connect(self.explore_planner._stop_explore_planner)
	self.infantry_strategy.attack.connect(self.group_planner._stop_group_planner)
	self.infantry_strategy.attack.connect(self.infantry_attack_planner._on_strategy_attack)
	self.infantry_strategy.explore.connect(self.explore_planner._on_strategy_explore)
	self.infantry_strategy.explore.connect(self.group_planner._stop_group_planner)
	self.infantry_strategy.explore.connect(self.infantry_attack_planner._stop_attack_planner)
	self.infantry_strategy.regroup.connect(self.explore_planner._stop_explore_planner)
	self.infantry_strategy.regroup.connect(self.group_planner._on_strategy_regroup)
	self.infantry_strategy.regroup.connect(self.infantry_attack_planner._stop_attack_planner)
	
	self.obstacle_map.send_exploration_target.connect(self.explore_planner._on_obstacle_map_send_exploration_target)
	self.obstacle_map.send_path.connect(self.pathfinder._on_obstacle_map_send_path)
	self.obstacle_map.update_done.connect(self.vision._on_obstacle_map_update_done)
	
	self.pathfinder.destination_reached.connect(self.explore_planner._on_pathfinder_destination_reached)
	self.pathfinder.new_waypoint.connect(self._on_pathfinder_new_waypoint)
	self.pathfinder.request_path.connect(self.obstacle_map._on_pathfinder_request_path)
	
	self.vision.danger.connect(self.infantry_strategy._on_enemy_danger)
	self.vision.enemy_sighted.connect(self.enemy_tracker._on_enemy_sighted)
	self.vision.enemy_lost.connect(self.enemy_tracker._on_enemy_lost)
	self.vision.obstacles_sighted.connect(self.obstacle_map._on_obstacle_sighted)
	self.vision.ready_to_fight.connect(self.infantry_attack_planner._on_ready_to_fight)
	self.vision.ready_to_fight.connect(self._on_ready_to_fight)
	
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


func _share_map_at_regroup_point() -> void:
	self.share_map.emit(self.obstacle_map.grid)


func _on_map_receive(map: Grid2D) -> void:
	self.obstacle_map.compare_map(map)


#-----------------------------------------------------------------------------#
# RotateBody State
func _on_rotate_body_state_processing(delta: float) -> void:
	var target_direction = self.global_position.direction_to(self.target_waypoint)
	self.global_rotation = lerp_angle(self.global_rotation, target_direction.angle(), delta * 5)
	
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
