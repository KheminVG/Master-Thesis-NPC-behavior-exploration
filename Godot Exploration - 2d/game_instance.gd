# This code is based on work by Joshua Moelans
# https://github.com/JoshuaMoelans/Master-Thesis-Godot-exploration (accessed March 2025)
# Originally developed for his master's thesis at the University of Antwerp

extends Node2D
class_name GameInstance

@export var verbose = false
@export var id = 0
@export var TILE_SIZE: int = 64
@onready var area: CollisionShape2D = $Bounds/area

var game_state: GameState; # the current game state
var agent_count = 0
var agents_finished = 0

func _ready() -> void:
	game_state = GameState.new()
	game_state.game_instance_name = name


func _process(delta):
	game_state.update_time += delta


func calculate_instance_position(grid_dim: int, i: int) -> Vector2:
	var size = area.get_shape().get_rect().size
	var x = (i%grid_dim)*(size.x + 350)
	var y = (floor(i/grid_dim))*(size.y + 350)
	
	return Vector2(x, y)


func setup():
	for child in get_children():
		if child is BehaviorAgent:
			child.setup()
			game_state.add_agent(child.get_agent_state())
			child.state_changed.connect(game_state.update_agent_state)
			child.finished.connect(agent_finishes)
			agent_count += 1


func assign_parameters(args) -> void:
	pass


func set_flush_state(b: bool):
	game_state.flush = b


func stop_instance(allies_won:bool):
	print("game over in instance: ", name)
	if allies_won:
		$"Game Over/AlliesWon".visible = true
	else:
		$"Game Over/EnemiesWon".visible = true
	game_state.state_update(true, "", false, true)


func get_map_dimensions() -> Dictionary:
	var dimensions: Dictionary = {}
	
	dimensions["size"] = area.get_shape().get_rect().size
	dimensions["tile_size"] = TILE_SIZE
	dimensions["instance_offset"] = position
	
	return dimensions

func agent_finishes(agent_state) -> void:
	game_state.update_agent_state(agent_state)
	agents_finished += 1
	
	# Check if all agents have finished
	if agents_finished == agent_count:
		game_state.state["agent_map_comparison"] = []
		for agent in game_state.state.agents:
			for other in game_state.state.agents:
				if agent == other:
					continue
				
				if game_state.state.agents[agent]["map"] != game_state.state.agents[other]["map"]:
					var error: String = agent + " and " + other + " failed the map sanity check"
					game_state.state["agent_map_comparison"].append(error)
		
		for agent in game_state.state.agents:
			print(agent)
			print(game_state.state.agents[agent]["map"])
		stop_instance(true)


class GameState:
	var flush = false # whether to attempt to flush the game state
	var update_time = 0
	var state = {};
	var teams = ["agents"]
	var game_instance_name = ""
	
	signal state_flush(filename, data)
	
	func _init():
		state["agents"] = {}
	
	func add_agent(agent_state, team = "agents"):
		self.state[team][agent_state.name] = agent_state
	
	func update_agent_state(newstate):
		newstate["timer"] = update_time
		self.state["agents"][newstate.name] = newstate
		state_update()
	
	func state_update(force=false, suffix="", timeout=false, gameover=false):
		if force or flush:
			self.state["timer"] = update_time
			var filename = game_instance_name + "_" + str(update_time) + suffix
			if timeout:
				filename = game_instance_name + "_" + "TIMEOUT"
			if gameover:
				filename = game_instance_name + "_" + "GAMEOVER"
			state_flush.emit(filename, JSON.stringify(state))
