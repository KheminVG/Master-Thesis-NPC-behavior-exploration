extends Node2D
class_name ObstacleMap

signal send_path(path: Array[Vector2])
signal send_exploration_target(target: Vector2)

@onready var behavior: StateChart = $Behavior
var grid: Grid2D
var pathfinding: AStar = AStar.new()

# TODO figure out how to initialize the map. (what is the size)
# TODO how will we keep track of the fueling station locations. (known beforehand?)
# TODO figure out how to fill in the free tiles

# Callable to connect to any Radar's obstacle_sighted signals
func _on_radar_obstacle_sighted(obstacles) -> void:
	self.behavior.send_event("update_map")
	self.grid.fill_obstacles(obstacles)


# Callable to connect to Pathfinder's request_path signal
func _on_pathfinder_request_path(pos: Vector2, destination: Vector2) -> void:
	var start = self.grid.global_to_tile(pos)
	var goal = self.grid.global_to_tile(destination)
	var path = self.pathfinding.astar(self.grid, start, goal)
	path = self.grid.path_to_global(path)
	self.send_path.emit(path)

# Callable to connect to ExplorePlanner's request_exploration_target
func _on_explore_planner_request_exploration_target(pos: Vector2):
	var target = self.grid.new_exploration_target(pos)
	target = self.grid.tile_to_global(target)
	self.send_exploration_target.emit(target)
