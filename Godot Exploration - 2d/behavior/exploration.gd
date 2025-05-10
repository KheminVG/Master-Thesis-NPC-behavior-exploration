extends BehaviorAgent
class_name ExplorationAgent

enum State {FINISH, AVOID, EXPLORE, IDLE, UPDATE, WALK}

@onready var exploration: Timer = $Exploration

var current_state: int = -1 : set = set_state, get = get_state
var previous_state: int = -1
var pathfinding: AStar = AStar.new()
var exploration_path: Array[Vector2i] = []

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	check_vision()
	match current_state:
		State.AVOID:
			avoid_collision()
			rotate_to(current_direction)
			set_state(State.WALK)
		State.EXPLORE:
			var start = map.global_to_tile(global_position)
			var goal = new_exploration_target(start)
			if goal == null:
				set_state(State.IDLE)
			else:
				exploration_path = pathfinding.astar(map, start, goal)
				set_state(State.WALK)
		State.FINISH:
			pass
		State.IDLE:
			pass
		State.UPDATE:
			# Check if agent is done exploring
			if map.explored():
				exploration.stop()
				update_agent_state()
				self.finished.emit(agent_state)
				set_state(State.FINISH)
			else:
				update_agent_state()
				set_state(State.WALK)
			
		State.WALK:
			if not exploration_path.is_empty():
				if global_position.distance_to(map.tile_to_global(exploration_path[0])) <= 24.0:
					stop_agent()
					exploration_path.pop_front()
				else:
					var next_path_position = map.tile_to_global(exploration_path[0])
					
					var new_direction = global_position.direction_to(next_path_position)
					change_direction(new_direction)
					rotate_to(current_direction)
					
					var new_velocity : Vector2 = current_direction * speed
					velocity = new_velocity
					move_and_slide()
			else:
				stop_agent()
				set_state(State.EXPLORE)

func setup():
	build_empty_map()
	
	exploration.set_wait_time(5)
	exploration.start()
	
	var new_direction = Vector2(1, 0)
	change_direction(new_direction)
	init_agent_state()
	set_state(State.WALK)

func get_state() -> int:
	return current_state

func set_state(new_state: int):
	if current_state == new_state:
		return # early exit if no change needed
	previous_state = current_state
	current_state = new_state

func get_tile_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var directions = [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1)]
	
	var neighbors = []
	for vec in directions:
		var neighbor = pos + vec
		if neighbor.x < map._size.x and neighbor.y < map._size.y:
			neighbors.append(neighbor)
	
	return neighbors

func change_direction(direction: Vector2):
	var current_map_tile = map.global_to_tile(global_position)
	current_direction = direction

func check_vision():
	# Awaiting the SceneTree's process_frame signal. Otherwise, the rays can be cast without 
	# having any objects to collide with in the very first frame. This is caused by the 
	# TileMapLayer is not fully set up yet.
	await get_tree().process_frame
	
	for ray in vision.get_children():
		var seen_tiles: Array[Vector2i] = []
		if ray.is_colliding():
			var collision = ray.get_collision_point()
			
			if global_position.distance_to(collision) <= 24.0:
				set_state(State.AVOID)
			
			# Collisions with other agents are not marked on the map as obstacles
			if ray.get_collider() is BehaviorAgent:
				continue
			
			# Ignore collision when colliding with a corner of a map tile. The normal at the point
			# of collision is not defined and results unexpected map updates.
			if not int(collision.x) % map._tile_size and not int(collision.y) % map._tile_size:
				continue
			
			# We use the collision normal correct the position of the collision before translating 
			# the coordinates to the map grid.
			var normal = ray.get_collision_normal()
			
			# Mark the colliding tile as OBSTACLE (1)
			var collision_tile = map.global_to_tile(collision - normal)
			map.set_tile_value(collision_tile, 1)
			
			seen_tiles = map.dda_ray_tiles(ray.global_position, collision + normal)
		else:
			seen_tiles = map.dda_ray_tiles(ray.global_position, to_global(ray.target_position))
		
		for tile in seen_tiles:
			map.set_tile_value(tile, 0)

func new_exploration_target(current: Vector2i):
	var frontier: MaxHeap = map.get_frontier_utilities(current)
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

func _on_exploration_timeout() -> void:
	set_state(State.UPDATE)
