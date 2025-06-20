extends Node2D
class_name ExplorePlanner

signal request_exploration_target(pos: Vector2)
signal new_destination(pos: Vector2)
signal done

@onready var behavior: StateChart = $Behavior
@onready var exploring: AtomicState = $Behavior/ExploreStrategy/Exploring

#-----------------------------------------------------------------------------#
# Exploring State

# Callable to connect to Pathfinder's destination_reached signal
func _on_pathfinder_destination_reached():
	if exploring.active:
		self.behavior.send_event("new_target")


# Callable to connect to ObstacleMap's send_exploration_target signal
func _on_obstacle_map_send_exploration_target(target) -> void:
	if target == null:
		self.done.emit()
		return
	
	if self.exploring.active:
		self.new_destination.emit(target)


func _on_exploring_state_entered() -> void:
	self.request_exploration_target.emit(self.global_position)


# Callable to connect to PilotStrategy's attack signal
func _stop_explore_planner() -> void:
	self.behavior.send_event("stop")


#-----------------------------------------------------------------------------#
# Idle State

# Callable to connect to PilotStrategy's explore signal
func _on_strategy_explore() -> void:
	self.behavior.send_event("explore")
