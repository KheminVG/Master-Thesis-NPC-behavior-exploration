extends Node2D
class_name Pathfinder

signal new_waypoint(waypoint: Vector2)
signal destination_reached
signal request_path(start: Vector2, goal: Vector2)

@onready var behavior: StateChart = $Behavior

var pathfinding: AStar = AStar.new()
var waypoints: Array[Vector2i] = []
var destination = null

func set_destination(dest: Vector2) -> void:
	self.destination = dest

func more_waypoints() -> bool:
	if self.waypoints.is_empty():
		return false
	else:
		return true

#-----------------------------------------------------------------------------#
# Idle State

# Callable to connect to any new_destination signals
func _on_new_destination(pos):
	self.set_destination(pos)
	self.behavior.send_event("new_destination")


# Callable to connect to TankBody's Radar's obstacle_sighted signal.
func _on_tank_body_radar_obstacle_sighted():
	self.behavior.send_event("obstacle_ahead")


# Callable to connect to Tank's waypoint_reached signal.
func _on_tank_waypoint_reached():
	self.behavior.send_event("waypoint_reached")


#-----------------------------------------------------------------------------#
# RequestPath State
func _on_request_path_state_entered() -> void:
	self.request_path.emit(self.global_position, self.destination)

# Callable to connect to ObstacleMap's send_path signal
func _on_obstacle_map_send_path(path: Array[Vector2i]) -> void:
	self.waypoints = path
	self.behavior.send_event("received_path")

#-----------------------------------------------------------------------------#
# ReceivedPath State
func _on_received_path_state_entered() -> void:
	if self.more_waypoints():
		self.behavior.send_event("new_waypoint")
	else:
		self.behavior.send_event("no_path")


func _on_new_waypoint_taken() -> void:
	self.new_waypoint.emit(self.waypoints.pop_front())


#-----------------------------------------------------------------------------#
# CheckWaypoints State
func _on_check_waypoints_state_entered() -> void:
	if self.more_waypoints():
		self.behavior.send_event("next_waypoint")
	else:
		self.behavior.send_event("destination_reached")


func _on_next_waypoint_taken() -> void:
	self.new_waypoint.emit(self.waypoints.pop_front())


func _on_destination_reached_taken() -> void:
	self.destination_reached.emit()


#-----------------------------------------------------------------------------#
