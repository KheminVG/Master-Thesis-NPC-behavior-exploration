class_name Grid2D
extends RefCounted

var NEIGHBOR_DIRECTIONS = [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1)]

var _data: Array[Grid2DTile]
var _size: Vector2i
var _tile_size: int
var _grid_origin: Vector2

func _init(size: Vector2i, tile_size: int, origin: Vector2, start_pos: Vector2, data: Array = []) -> void:
	if not data.is_empty():
		assert(data.size() == size.x * size.y, "Given data does not match the specified size.")
	
	if not data.is_empty() and data.size() == size.x * size.y:
		self._data = data
	else:
		self._data = []
	
	self._size = size
	self._tile_size = tile_size
	self._grid_origin = origin
	
	# Fill all tiles of the map in with UNKOWN (-1).
	var cell_count = _size.x * _size.y
	for i in cell_count:
		var x: int = i % self._size.x
		var y: int = i / self._size.x
		var tile: Grid2DTile = Grid2DTile.new(x, y, -1)
		_data.append(tile)
	
	# Fill in the starting position as FREE (0). The agent using this map will start exploring from this position.
	self.set_tile_value(self.global_to_tile(start_pos), 0)

func get_tile(pos: Vector2i) -> Grid2DTile:
	var index = pos.x + (pos.y * self._size.x)
	return self._data[index]

func set_tile_value(pos: Vector2i, value: int) -> void:
	var index = pos.x + (pos.y * self._size.x)
	self._data[index].val = value

func fill_obstacles(obstacles: Array[Vector2i]) -> void:
	for obs in obstacles:
		self.set_tile_value(obs, 1)

func fill_free_space(free_space: Array[Vector2i]) -> void:
	for free in free_space:
		self.set_tile_value(free, 0)

func manhattan_distance(a: Vector2i, b: Vector2i):
	return abs(a.x - b.x) + abs(a.y - b.y)

func global_to_tile(global_pos: Vector2) -> Vector2i:
	# TODO check if global_pos is inside the bounds of this grid
	var instance_position = global_pos - self._grid_origin
	var tile_x: int = floori(instance_position.x / self._tile_size)
	var tile_y: int = floori(instance_position.y / self._tile_size)
	
	return Vector2i(tile_x, tile_y)

func tile_to_global(grid_pos: Vector2i) -> Vector2:
	# TODO check if given grid position is within the bounds of this grid
	var global_x: float = self._grid_origin.x + (grid_pos.x * self._tile_size) + (self._tile_size/2)
	var global_y: float = self._grid_origin.y + (grid_pos.y * self._tile_size) + (self._tile_size/2)
	
	return Vector2(global_x, global_y)

func path_to_global(path: Array[Vector2i]) -> Array[Vector2]:
	var global_path: Array[Vector2] = []
	
	for waypoint in path:
		global_path.append(self.tile_to_global(waypoint))
	
	return global_path

func explored() -> bool:
	return self.get_frontier_tiles().is_empty()

func get_neighbor_values(pos: Vector2i) -> Dictionary[Vector2i, int]:
	var values: Dictionary[Vector2i, int] = {}
	for direction in NEIGHBOR_DIRECTIONS:
		var neighbor: Vector2i = pos + direction
		if 0 <= neighbor.x and neighbor.x < self._size.x and 0 <= neighbor.y and neighbor.y < self._size.y:
			values[neighbor] = self.get_tile(neighbor).val
	
	return values

func get_frontier_tiles() -> Array[Vector2i]:
	var frontier: Array[Vector2i] = []
	for y in self._size.y:
		for x in self._size.x:
			var pos: Vector2i = Vector2i(x, y)
			if self.get_tile(pos).val == 0 and self.get_neighbor_values(pos).values().find(-1) != -1:
				frontier.append(pos)
	return frontier

func compute_utility(pos: Vector2i, agent_pos: Vector2i, radius: int = 2) -> float:
	# TODO update utility calculation
	# NOW: just counting the amount of unknown tiles in a radius around the given tile position
	# IDEAS: 
	# 	take position (and/or direction) of the agent into acount ( higher utility for closer tiles and in same direction )
	# 	keep count of number of visits to a tile. penalize utility for visiting a tile very often ( fresh explore )
	var count = 0
	for dx in range(-radius, radius+1):
		for dy in range(-radius, radius+1):
			var neighbor: Vector2i = pos + Vector2i(dx, dy)
			if 0 <= neighbor.x and neighbor.x < self._size.x and 0 <= neighbor.y and neighbor.y < self._size.y and self.get_tile(neighbor).val == -1:
				count += 1
	
	var utility = count
	var distance = self.manhattan_distance(agent_pos, pos)
	if distance > 0:
		utility /= distance
	
	return utility

func get_frontier_utilities(agent_pos: Vector2i) -> MaxHeap:
	var frontier_utilities: MaxHeap = MaxHeap.new() 
	var frontier_tiles: Array[Vector2i] = self.get_frontier_tiles()
	for tile in frontier_tiles:
		var utility: float = self.compute_utility(tile, agent_pos)
		var heap_node: HeapNode = HeapNode.new(tile, utility)
		frontier_utilities.push(heap_node)
	return frontier_utilities

func new_exploration_target(position: Vector2):
	var current: Vector2i = self.global_to_tile(position)
	var frontier: MaxHeap = self.get_frontier_utilities(current)
	if not frontier.empty():
		var target: Vector2i = frontier.pop().position
	
		# If the first returned target is the same as the current tile, we take the next best tile 
		# in the frontier.
		if target == current and not frontier.empty():
			return frontier.pop().position
		elif target == current and frontier.empty():
			return null
		return target
	else: 
		return null

func fill_enclosed_unknown_regions() -> void: 
	var visited: Dictionary = {}
	
	for y in self._size.y:
		for x in self._size.x:
			var pos: Vector2i = Vector2i(x, y)
			if self.get_tile(pos).val == -1 and pos not in visited.keys():
				
				var region: Array = []
				var is_enclosed: bool = true
				var queue: Array = [pos]
				
				# Flood fill loop
				while not queue.is_empty():
					var current: Vector2i = queue.pop_front()
					if current in visited.keys():
						continue
					
					visited[current] = true
					region.append(current)
					
					for direction in NEIGHBOR_DIRECTIONS:
						var neighbor: Vector2i = current + direction
						
						# Grid Bounds Check
						if 0 <= neighbor.x and neighbor.x < self._size.x and 0 <= neighbor.y and neighbor.y < self._size.y:
							if self.get_tile(neighbor).val == -1 and neighbor not in visited.keys():
								queue.push_back(neighbor)
							elif self.get_tile(neighbor).val == 0:
								# Connected to FREE (0) tile => region is not enclosed
								is_enclosed = false
				
				# If the region is enclosed, mark all tiles in the region as OBSTACLE (1)
				if is_enclosed:
					for el in region:
						self.set_tile_value(el, 1)

func dda_ray_tiles(global_start: Vector2, global_end: Vector2) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	
	var start: Vector2 = (global_start - self._grid_origin) / self._tile_size
	var end: Vector2 = (global_end - self._grid_origin) / self._tile_size
	
	var dx = end.x - start.x
	var dy = end.y - start.y
	
	var step_x = 1 if dx > 0 else -1
	var step_y = 1 if dy > 0 else -1
	
	var tile = self.global_to_tile(global_start)
	var end_tile = self.global_to_tile(global_end)
	
	var tile_corr_x = 1 if step_x > 0 else 0
	var tile_corr_y = 1 if step_y > 0 else 0
	
	var t_max_x = ((tile.x + tile_corr_x) - start.x) / dx if dx !=0 else INF
	var t_max_y = ((tile.y + tile_corr_y) - start.y) / dy if dy !=0 else INF
	
	var t_delta_x = abs(1/dx) if dx !=0 else INF
	var t_delta_y = abs(1/dy) if dy !=0 else INF
	
	var max_steps = 100
	for step in max_steps:
		tiles.append(tile)
		
		if t_max_x < t_max_y:
			t_max_x += t_delta_x
			tile.x += step_x
		else:
			t_max_y += t_delta_y
			tile.y += step_y
		
		if (
			(step_x > 0 and tile.x > end_tile.x) or
			(step_x < 0 and tile.x < end_tile.x) or
			(step_y > 0 and tile.y > end_tile.y) or
			(step_y < 0 and tile.y < end_tile.y) 
		):
			break
	
	return tiles

func stringify_grid2d() -> String:
	var map_string = ""
	for y in self._size.y:
		for x in self._size.x:
			var entry = get_tile(Vector2i(x, y))
			if entry.val == 1:
				map_string += "x"
			elif entry.val == 0:
				map_string += " "
			elif entry.val == -1:
				map_string += "?"
		map_string += "\n"
	return map_string

class Grid2DTile:
	var val: int
	var pos: Vector2i
	
	func _init(x: int, y: int, value: int) -> void:
		self.val = value
		self.pos = Vector2i(x, y)
