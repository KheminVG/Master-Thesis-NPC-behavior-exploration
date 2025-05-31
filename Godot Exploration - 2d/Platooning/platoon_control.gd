extends Node2D
class_name PlatoonControl

signal explore_destination(destination: Vector2, name: StringName)

@onready var obstacle_map: ObstacleMap = $ObstacleMap
@onready var explore_control: ExploreControl = $ExploreControl
@onready var platoon_control_strategy: PlatoonControlStrategy = $PlatoonControlStrategy
@onready var communicator: Communicator = $Communicator
@onready var team: Node2D = $team

var idle_agents: Array[OrchastratedInfantry] = []
var _map_initialized: bool = false


func _ready() -> void:
	for agent: OrchastratedInfantry in team.get_children():
		idle_agents.append(agent)
		
		agent.communicator.send.connect(self.communicator._add_incoming)
	
	self.platoon_control_strategy.explore.connect(self.explore_control._on_strategy_explore)
	self.explore_control.request_exploration_target.connect(self.obstacle_map._on_explore_planner_request_exploration_target)
	self.obstacle_map.send_exploration_target.connect(self.explore_control._on_obstacle_map_send_exploration_target)
	
	self.explore_control.new_destination.connect(self._on_explore_destination)

func get_map_dimensions() -> Dictionary:
	if self.get_parent() is PlatoonTestInstance:
		return self.get_parent().get_map_dimensions()
	else: return {}

func _on_explore_destination(target: Vector2) -> void:
	var closest_idx: int = 0
	
	for i in self.idle_agents.size():
		var agent: OrchastratedInfantry = self.idle_agents[i]
		var closest_agent: OrchastratedInfantry = self.idle_agents[closest_idx]
		if (agent.global_position.distance_to(target) < closest_agent.global_position.distance_to(target)):
			closest_idx = i
	
	self.explore_destination.emit(target, self.idle_agents[closest_idx].name)
	self.idle_agents.remove_at(closest_idx)


func _on_map_init_state_entered() -> void:
	if not self._map_initialized:
		# Initialize the empty ObstacleMap by getting the dimensions from the world.
		var dimensions = self.get_map_dimensions()
		self.obstacle_map.build_empty_map(dimensions)
		self._map_initialized = true
