extends BehaviorAgent
class_name RandomWalkAgent

enum State {FINISH, AVOID, IDLE, RANDOM, UPDATE, WALK}

@onready var exploration: Timer = $Exploration

var current_state: int = -1 : set = set_state, get = get_state
var previous_state: int = -1
var action_weights: Dictionary = {"left": 30, "right": 30, "front": 40}

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	check_vision()
	match current_state:
		State.AVOID:
			avoid_collision()
			rotate_to(current_direction)
			set_state(State.WALK)
		State.FINISH:
			pass
		State.IDLE:
			pass
		State.RANDOM:
			var new_direction = perform_random_rotate_action(current_direction)
			change_direction(new_direction)
			set_state(State.WALK)
		State.UPDATE:
			# Check if agent is done exploring
			if map.explored():
				exploration.stop()
				update_agent_state()
				self.finished.emit(agent_state)
				set_state(State.FINISH)
			else:
				update_agent_state()
				set_state(State.RANDOM)
		State.WALK:
			rotate_to(current_direction)
			var new_velocity : Vector2 = current_direction * speed
			velocity = new_velocity
			move_and_slide()

func setup():
	build_empty_map()
	
	exploration.set_wait_time(4)
	exploration.start()
	
	var new_direction = generate_patrol_direction()
	#var new_direction = Vector2i(-1, 0)
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

func change_direction(direction: Vector2):
	var current_map_tile = map.global_to_tile(global_position)
	current_direction = direction

func avoid_collision():
	stop_agent()
		
	var new_direction: Vector2
	if randi_range(0, 4):
		new_direction = utils.rotate_vec_right(current_direction)
	else:
		new_direction = utils.rotate_vec_left(current_direction)
	change_direction(new_direction)

func check_vision():
	# Awaiting the SceneTree's process_frame signal. Otherwise, the rays can be cast without 
	# having any objects to collide with in the very first frame. This is caused by the 
	# TileMapLayer is not fully set up yet.
	await get_tree().process_frame
	
	for ray: RayCast2D in vision.get_children():
		var seen_tiles: Array[Vector2i] = []
		if ray.is_colliding():
			var collision = round(ray.get_collision_point())
			
			if global_position.distance_to(collision) <= 24.0:
				set_state(State.AVOID)
			
			# Collisions with other agents are not marked on the map as obstacles
			if ray.get_collider() is BehaviorAgent:
				continue
			
			# Ignore collision when colliding with a corner of a map tile. The normal at the point
			# of collision is not defined and results in unexpected map updates.
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

func generate_patrol_direction():
	var patrol_x = randi_range(-1, 1)
	var patrol_y = randi_range(-1, 1)
	
	var direction
	if patrol_x:
		direction = Vector2(patrol_x, 0)
	elif patrol_y:
		direction = Vector2(0, patrol_y)
	else:
		direction = Vector2(1, 0)
	
	return direction

func perform_random_rotate_action(direction: Vector2) -> Vector2:
	var total_weight = 100.0
	var threshold = randf_range(0.0, total_weight)
	var accumulated_weight = 0.0
	var actions = action_weights.keys()
	var pick = ""
	for action in actions:
		accumulated_weight += action_weights[action]
		if accumulated_weight >= threshold: 
			pick = action
			break
	
	if pick == "left":
		return utils.rotate_vec_left(direction)
	if pick == "right":
		return utils.rotate_vec_right(direction)
	if pick == "front":
		return direction
	
	return direction

func _on_exploration_timeout() -> void:
	stop_agent()
	set_state(State.UPDATE)
	#print(map.stringify_grid2d())
