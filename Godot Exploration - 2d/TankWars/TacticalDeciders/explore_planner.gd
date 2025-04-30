extends Node2D
class_name ExplorePlanner

signal request_exploration_target(pos: Vector2)
signal new_destination(pos: Vector2)

@onready var behavior: StateChart = $Behavior
@onready var exploring: AtomicState = $Behavior/ExploreStrategy/Exploring

#-----------------------------------------------------------------------------#
# Exploring State

# Callable to connect to Pathfinder's destination_reached signal
func _on_pathfinder_destination_reached():
	self.behavior.send_event("new_target")


func _on_new_target_taken() -> void:
	self.request_exploration_target.emit(self.global_position)

# Callable to connect to ObstacleMap's send_exploration_target signal
func _on_obstacle_map_send_exploration_target(target: Vector2) -> void:
	if self.exploring.active:
		self.new_destination.emit(target)


# Callable to connect to PilotStrategy's attack signal
func _on_pilot_strategy_attack() -> void:
	self.behavior.send_event("attack")


#-----------------------------------------------------------------------------#
# Idle State

# Callable to connect to PilotStrategy's explore signal
func _on_pilot_startegy_explore() -> void:
	self.behavior.send_event("explore")
