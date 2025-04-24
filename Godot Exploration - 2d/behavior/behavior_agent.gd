extends CharacterBody2D
class_name BehaviorAgent

# Reference used to instantiate instance of Utils class. Similar to importing.
# Can make use of the methods in Utils.gd by calling them on this instance.
var utils: Utils = Utils.new()

enum TeamName { ALLY , ENEMY }
@export var team: TeamName = TeamName.ALLY
@export var health: int = 100 : set = set_health, get = get_health
@export var speed: int = 150

@onready var vision: Node2D = $vision

var current_direction: Vector2
var behavior_trace: String = ""

var map: Grid2D

var agent_state: Dictionary = {}

signal state_changed(new_state)
signal finished(state)

func _ready() -> void:
	pass
	

func _physics_process(delta: float) -> void:
	pass

func setup():
	build_empty_map()
	init_agent_state()

func set_health(h:int) -> void:
	health = clamp(h,0,100)

func get_health() -> int:
	return health

func rotate_to(direction: Vector2):
	rotation = lerp_angle(rotation, direction.angle(), 0.8)

func stop_agent() -> void:
	velocity.x = move_toward(velocity.x, 0, speed)
	velocity.y = move_toward(velocity.y, 0, speed)
	move_and_slide()

func get_team() -> int:
	return team

func get_agent_state() -> Dictionary:
	return agent_state

func change_direction(direction: Vector2):
	var current_map_tile = map.global_to_tile(global_position)
	behavior_trace += "Location: (" + str(current_map_tile.x) + "," + str(current_map_tile.y) + ")\n"
	current_direction = direction

func avoid_collision():
	stop_agent()
		
	var new_direction: Vector2
	new_direction = utils.rotate_vec_left(current_direction)
	change_direction(new_direction)

func check_vision():
	pass

func build_empty_map():
	var instance: GameInstance = get_parent()
	var dimensions: Dictionary = instance.get_map_dimensions()
	
	var size: Vector2 = dimensions["size"]
	var map_tile_size = dimensions["tile_size"]
	var map_origin = dimensions["instance_offset"]
	
	var tile_count_x: int = floori(size.x / map_tile_size)
	var tile_count_y: int = floori(size.y / map_tile_size)
	
	var map_size = Vector2i(tile_count_x, tile_count_y)
	map = Grid2D.new(map_size, map_tile_size, map_origin, global_position)

func init_agent_state():
	agent_state["name"] = self.get_name()
	agent_state["map"] = self.map.stringify_grid2d()
	#agent_state["trace"] = self.behavior_trace

func update_agent_state():
	agent_state["map"] = self.map.stringify_grid2d()
	#agent_state["trace"] = self.behavior_trace
	
	self.state_changed.emit(agent_state)
