extends Node2D
class_name GroupPlanner

signal clear_pathfinding
signal new_destination(pos: Vector2)
signal reached_regroup
signal request_reference


var _regroup_point: Vector2 = Vector2(0.0, 0.0)
@export var _regroup_margin: float = 50.0
@onready var behavior: StateChart = $Behavior


func set_regroup_point(point: Vector2) -> void:
	self._regroup_point = point


# Callable to connect to Strategy's regroup signal
func _on_strategy_regroup() -> void:
	self.behavior.send_event("regroup")


# Callable to connect to any signal that wants to halt the GroupPlanner
func _stop_group_planner() -> void:
	self.behavior.send_event("stop")


#------------------------------------------------------------------------------#
# Regroup State
func _on_regroup_state_entered() -> void:
	self.new_destination.emit(self._regroup_point)


func _on_regroup_state_processing(delta: float) -> void:
	if self.global_position.distance_to(self._regroup_point) <= self._regroup_margin:
		self.clear_pathfinding.emit()
		self.behavior.send_event("regrouped")


#------------------------------------------------------------------------------#
# Formation/Idle State
func _on_formation_idle_state_entered() -> void:
	self.reached_regroup.emit()
	self.request_reference.emit()


# TODO Think about how to set up and maintain formation
func _on_request_reference() -> void:
	pass
