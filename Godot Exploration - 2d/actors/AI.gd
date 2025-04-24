extends Node2D
class_name AI

@onready var patrol_timer = $PatrolTimer
@onready var path_line = $PathLine

@export var should_draw_path_line: bool = false

signal state_changed(new_state)

# state machine
enum State{
	PATROL,
	ENGAGE,
	ADVANCE,
	REPOSITION,  # state to use when trying to move into new position
	ROTATE # state to force rotation
}

var current_state: int = -1 : set = set_state, get = get_state
var previous_state: int = -1
var actor: Actor = null
var target:CharacterBody2D = null
var weapon: Weapon = null
var team: int = -1

var pathfinding: Pathfinding
var initial_locations = []
var current_path = []
# PATROL STATE
var origin: Vector2 = Vector2.ZERO  # default position
var patrol_location: Vector2 = Vector2.ZERO
var patrol_location_reached: bool = false

var goal_margin = 25 # margin to reach their goal

var AI_State = {} # similar state structure for all agents

# ADVANCE STATE
var next_position: Vector2 = Vector2.ZERO
var vision_shape: CollisionShape2D = null

func _ready():
	path_line.visible = should_draw_path_line

@onready var detection_zone = $DetectionZone
func set_vision_cone(angle, distance):
	detection_zone.setCone(angle, distance)

func handle_reload():
	printhelper(actor, " reloading weapon", "")
	weapon.start_reload()
	update_AI_ammo(weapon.current_ammo)
	update_AI_reload()

func get_AI_state():
	return AI_State

func _physics_process(delta: float) -> void:
	var deltaspeed = delta * 50 # currently arbitrary choice of factor
	AI_State["position"] = global_position # TODO also flush whenever state change/checkpoint/patrol point?
	path_line.global_rotation = 0 # reset pathing line rotation
	match current_state:
		State.ROTATE:
			if not rotate_goal:
				set_state(previous_state)
				return
			actor.rotate_toward(rotate_goal)
			if abs(self.rotation - get_angle_to(rotate_goal)) < 0.01:
				rotate_goal = null
				set_state(previous_state)
		State.PATROL:
			if not patrol_location_reached:
				if current_path.size() == 0:
					# caching path for patrol
					update_AI_goal(patrol_location)
					current_path = pathfinding.get_new_path(global_position, patrol_location)
				var path = current_path
				update_AI_path(current_path)
				if path.size() > 1:
					actor.velocity = deltaspeed * actor.velocity_toward(path[1])
					actor.move_and_slide()
					actor.rotate_toward(path[1])
					set_path_line(path)
					if global_position.distance_to(path[1]) < 5:
						printhelper(actor, " reached next PATROL path point: ", path[1])
						current_path.pop_front()  # remove path steps one by one when reaching point
					# keep the line below to avoid 'clumping up' of units.
					# TODO could use tutorial 21.14:30 to do similar 'get random position'
				if global_position.distance_to(patrol_location) < goal_margin: # goal_margin to avoid getting stuck
					printhelper(actor, " reached PATROL location: ", patrol_location)
					patrol_location_reached = true
					actor.velocity = Vector2.ZERO
					patrol_timer.start()
					path_line.clear_points()
					current_path = []
		State.ENGAGE:
			if target_buffer.is_empty():
				set_state(previous_state)
				return
			var first_key = target_buffer.keys()[0]
			var target_check = target_buffer[first_key]
			
			if target_check == null:
				target_buffer.erase(first_key)  # only pop once target no longer exists
				return
			
			self.target = target_check
			if target != null and weapon != null:
				# use global coordinates, not local to node
				var result = has_line_of_fire(target)
				if result.is_empty():
					set_state(previous_state)
					return
				# TODO what if not hittable now, but by ally/enemy movement they get hittable?
				if not result["collider"].has_method("get_team"):  # check if raycast hits character
					set_state(previous_state)
					return
				elif result["collider"].get_team() == actor.get_team():  # check if same team
					set_state(previous_state) # TODO this prevents shooting towards team members; add parameter to avoid only sometimes?
					return
				printhelper(actor, " engaging rival at position: ", target.global_position)
				printhelper(actor, " engaging rival from position: ", actor.global_position)
				actor.rotate_toward(target.global_position)
				var angle_to_target = actor.global_position.direction_to(target.global_position).angle()
				if abs(actor.global_position.angle_to(target.global_position)) < 0.2:
					printhelper(actor, " shooting rival at position: ", target.global_position)
					printhelper(actor, " shooting rival from position: ", actor.global_position)
					update_AI_aim(target.global_position)
					weapon.shoot()
					update_AI_ammo(weapon.current_ammo)
			else:
				print("Engage state but lacking weapon/target")
				print("going back to previous state: ", previous_state)
				set_state(previous_state) # return to previous state
				#print("\t weapon is: ",str(weapon))
				#print("\t target is: ",str(target))
		State.ADVANCE, State.REPOSITION:
			if current_path.size() == 0:
				update_AI_goal(next_position)
				current_path = pathfinding.get_new_path(global_position, next_position)
			var path = current_path
			update_AI_path(current_path)
			if path.size() > 1:
				actor.velocity = deltaspeed * actor.velocity_toward(path[1])
				actor.move_and_slide()
				actor.rotate_toward(path[1])
				set_path_line(path)
				if global_position.distance_to(path[1]) < 5:
					printhelper(actor, " reached next ADVANCE path point: ", path[1])
					current_path.pop_front()  # remove path steps one by one when reaching point
			if current_state == State.REPOSITION:  # move until line of sight to target
				var los_check = has_line_of_fire(target)
				if not los_check.is_empty(): # if collider hit
					if los_check["collider"] == target:  # and hit target
						set_state(State.ENGAGE)
			# keep the line below to avoid 'clumping up' of units.
			# TODO maybe add slight randomization on goal position?
			if actor.global_position.distance_to(next_position) < goal_margin:
				printhelper(actor, " reached next ADVANCE position: ", next_position)
				current_path = []
				#print("arrived at advance position")
				if initial_locations.size() != 0:  # if more positions to cover
					next_position = initial_locations.pop_front()
					update_AI_init_locs(initial_locations)
				else:
					set_state(State.PATROL)

				path_line.clear_points()
		_:
			print("Error switch to non-existent state")

func has_line_of_sight(to):
	# Check if given target is reachable visually
	if to == null:
		return {}
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(actor.global_position, to.global_position)
	return space_state.intersect_ray(query)

func has_line_of_fire(to):
	# Check if given target is 'hittable' by firing
	if to == null:
		return {}
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(weapon.global_position, to.global_position)
	return space_state.intersect_ray(query)

func tactical_reposition(pos):
	# high priority move towards given position
	next_position = pos
	current_path = [] # clear path
	set_state(State.REPOSITION) # TODO why is this sometimes only thing that happens (see ally3)

func initialize(actor, weapon:Weapon, team:int):
	self.actor = actor
	self.weapon = weapon
	weapon.team = team
	self.team = team
	weapon.connect("weapon_out_of_ammo", handle_reload)
	init_AI_state()

func set_path_line(points: Array):
	if not should_draw_path_line:
		return
	var local_points := []
	for point in points:
		if point==points[0]:
			local_points.append(Vector2.ZERO)
		else:
			local_points.append(point - global_position)

	path_line.points = local_points

func set_weapon(weapon: Weapon):
	self.weapon = weapon

func set_state(new_state: int):
	if current_state == new_state:
		return # early exit if no change needed
	previous_state = current_state
	if current_state == State.ENGAGE:
		set_vision_range(1.0) # reset vision range (lower awareness)
	update_AI_prev_state(previous_state)
	current_state = new_state
	printhelper(actor, " entering state ", State.keys()[new_state])
	if new_state == State.PATROL:
		patrol_timer.autostart = true
		patrol_timer.start()
		origin = global_position
		patrol_location_reached = true
	elif new_state == State.ADVANCE:
		if actor.has_reached_position(next_position) and initial_locations.size() == 0:
			set_state(State.PATROL)
	update_AI_state(get_state())

func get_state() -> int:
	return current_state

signal organic_engage(unit, target)

func _on_detection_zone_body_entered(body):
	if body.has_method("get_team") and body.get_team() != team:
		organic_engage.emit(get_parent(), body) # signal up
		engage_target(body)

var target_buffer = {} # TODO think about priority buffer
var target_dict = {}
func engage_target(target):
	if not target_dict.has(target):  # only add if not in there yet
		target_buffer[target_buffer.size()] = target  # for now, use size to set priority (fcfs) TODO other metrics?
		target_dict[target] = target_buffer.size()-1
		#print(actor.name + " adding ", target.name, " to target buffer")
	set_state(State.ENGAGE)
	#print("\t", target_buffer)
	update_AI_target(target.name)

func set_vision_range(size):
	self.scale = Vector2(size, size) # scale is vision range

var rotate_goal = null
func rotate_towards(position):
	if get_state() != State.ENGAGE:
		rotate_goal = position
		set_state(State.ROTATE)
		print(actor.name, " set state to ROTATE")

func _on_detection_zone_body_exited(body):
	if target and body == target:
		set_state(previous_state)
		update_AI_aim(null)
		target = null  # TODO what if target dies, does this trigger?

func generate_patrol_location():
	var patrol_range = 150
	var min_patrol_range = 75
	var random_x = randf_range(-patrol_range, patrol_range)
	if random_x > 0:
		clamp(random_x, min_patrol_range, patrol_range)
	else:
		clamp(random_x, -patrol_range, -min_patrol_range)
	var random_y = randf_range(-patrol_range, patrol_range)
	if random_y > 0:
		clamp(random_y, min_patrol_range, patrol_range)
	else:
		clamp(random_y, -patrol_range, -min_patrol_range)
	return Vector2(random_x, random_y) + origin

func _on_patrol_timer_timeout():
	patrol_location = generate_patrol_location()
	while not pathfinding.check_position_clear(patrol_location):
		patrol_location = generate_patrol_location() #regenerate if not clear
	printhelper(actor, " set new PATROL destination: ", patrol_location)
	patrol_location_reached = false


# helper function; takes in actor, text and single piece of data to print
# gets current actor scope (container and instance) for output
func printhelper(actor, text, data):
	pass
	var container = actor.get_parent()
	var instance = container.get_parent()
	var mainOutputHandler : OutputHandler = instance.get_parent().get_parent().get_node("outputhandler")
	var output = instance.name + "/" + container.name + "/" + actor.name + text + str(data)
	mainOutputHandler.write_to_instance_buffer(instance.id, output)
	if instance.verbose: # don't print if not verbose
		print(output)

func init_AI_state():
	AI_State["id"] = actor.get_name()
	AI_State["position"] = actor.global_position # TODO check when to update?
	AI_State["health"] = actor.health.health
	AI_State["ammo"] = weapon.current_ammo
	AI_State["path"] = []
	AI_State["goal_position"] = null
	AI_State["aim_direction"] = null
	AI_State["target"] = null
	AI_State["state"] = State.PATROL
	AI_State["previous_state"] = State.PATROL
	AI_State["reload_count"] = 0
	AI_State["initial_locations"] = initial_locations

signal flush_AI_state_sgn (unit_name, newstate)

func flush_AI_state():
	flush_AI_state_sgn.emit(AI_State["id"], AI_State)

func update_AI_target(newtarget_id):
	AI_State["target"] = newtarget_id
	flush_AI_state()

func update_AI_init_locs(new_init_locs):
	AI_State["initial_locations"] = new_init_locs
	flush_AI_state()

func update_AI_state(newstate):
	AI_State["state"] = newstate
	flush_AI_state()

func update_AI_health(newhealth):
	AI_State["health"] = newhealth # if <=0 in State we know unit is dead

func update_AI_path(newpath):
	AI_State["path"] = newpath
	flush_AI_state()

func update_AI_ammo(newammo):
	AI_State["ammo"] = newammo
	flush_AI_state()

func update_AI_reload():
	AI_State["reload_count"] += 1
	flush_AI_state()

func update_AI_aim(aimdir):
	AI_State["aim_direction"] = aimdir
	flush_AI_state()

func update_AI_prev_state(previous):
	AI_State["previous_state"] = previous
	flush_AI_state()

func update_AI_goal(newgoal):
	AI_State["goal_position"] = newgoal
	flush_AI_state()
