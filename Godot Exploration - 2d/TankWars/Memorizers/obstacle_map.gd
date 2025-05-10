extends Node2D
class_name ObstacleMap

signal send_path(path: Array[Vector2])
signal send_exploration_target(target: Vector2)
signal update_done

@onready var behavior: StateChart = $Behavior
var grid: Grid2D
var pathfinding: AStar = AStar.new()


func build_empty_map(dimensions: Dictionary):
	var size: Vector2 = dimensions["size"]
	var map_tile_size = dimensions["tile_size"]
	var map_origin = dimensions["instance_offset"]
	
	var tile_count_x: int = floori(size.x / map_tile_size)
	var tile_count_y: int = floori(size.y / map_tile_size)
	
	var map_size = Vector2i(tile_count_x, tile_count_y)
	self.grid = Grid2D.new(map_size, map_tile_size, map_origin, self.global_position)


# Callable to connect to any Radar's obstacle_sighted signals
func _on_radar_obstacle_sighted(data, ray_origin) -> void:
	self.behavior.send_event("update_map")
	self.grid.update_map(data, ray_origin)
	self.update_done.emit()


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
	if target != null:
		target = self.grid.tile_to_global(target)
	self.send_exploration_target.emit(target)


# Timer to show map
func _on_timer_timeout() -> void:
	print(self.grid.stringify_grid2d())
