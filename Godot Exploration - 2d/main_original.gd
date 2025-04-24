extends Node2D

const GameOverscreen = preload("res://UI/game_over_screen.tscn")
var Game_Instance_Scene = preload("res://game_instance_battle.tscn")

@export var instance_num = 1;
@export var visible_games = true;
@export var flush_state = false;
@export var timeout:int = 0;
@export var start_minimized = false;
@export var timescale:float = 1.0
@onready var GAMES = $GAMES
@onready var player: Player = $Player
@onready var gui = $GUI
@onready var outputhandler = $outputhandler
@onready var openfile = $OpenFile
@onready var instanceUI = $FPS/instanceUI

func parse_CLA():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("-")] = key_value[1]
	return arguments

# LIST OF PARAMETERS BELOW!
@export var communication_count : int = 1 # number of units to notify when attacking
@export var communication_delay : float = 1.5 # takes 1.5s before notifying
@export var vision_distance : float = 300  # how far a unit can 'see'
@export var vision_angle : float = 60 # total vision angle (half above horizon, half below)
# READ IN PARAMETERS BELOW
func set_CLA_vars():
	var args = parse_CLA()
	if args.has("timeout"):
		if args["timeout"].is_valid_int():
			timeout = int(args["timeout"])
		else:
			print("ERROR! non-integer timeout specified")
	if args.has("ngames"):
		if args["ngames"].is_valid_int():
			instance_num = int(args["ngames"])
		else:
			print("ERROR! non-integer amount of ngames parameter")
	if args.has("visible"):
		if args["visible"] == "true":
			visible_games = true
		else:
			visible_games = false
	if args.has("communication_count"):
		if args["communication_count"].is_valid_int():
			communication_count = int(args["communication_count"])
	if args.has("communication_delay"):
		if args["communication_delay"].is_valid_float():
			communication_delay = float(args["communication_delay"])
	if args.has("vision_angle"):
		if args["vision_angle"].is_valid_float():
			vision_angle = float(args["vision_angle"])
	if args.has("vision_distance"):
		if args["vision_distance"].is_valid_float():
			vision_distance = float(args["vision_distance"])
	if args.has("start_minimized"):
		if args["start_minimized"] == "true":
			start_minimized = true
		else:
			start_minimized = false
	if args.has("timescale"):
		if args["timescale"].is_valid_float():
			timescale = args["timescale"]
		

# Called when the node enters the scene tree for the first time.
# using deferred setup due to navigationserver error
# see https://github.com/godotengine/godot/issues/84677
func _ready():
	set_CLA_vars()
	if start_minimized:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	if timeout > 0:
		$TimeOut.wait_time = timeout
		$TimeOut.start()
	seed(0) # doesnt 100% work!
	Engine.set_time_scale(timescale)
	set_physics_process(false)
	setup()
	
func _physics_process(delta):
	if Input.is_action_just_pressed("toggle_visibility"):
		for game_instance in GAMES.get_children():
			game_instance.visible = not game_instance.visible
	if Input.is_action_just_pressed("load"):
		GAMES.process_mode = Node.PROCESS_MODE_DISABLED
		openfile.popup()
	if Input.is_action_just_pressed("save"):
		for game_instance:GameInstance in GAMES.get_children():
			game_instance.game_state.state_update(true)
	if Input.is_action_pressed("set_instances"):
		instanceUI.visible = true

func setup_instance(i:int):
	var grid_dim:int = ceil(sqrt(instance_num))
	# instance a Game_Instance from the Game_Instance scene
	var new_game_instance:GameInstance = Game_Instance_Scene.instantiate()
	new_game_instance.name = "game_instance_" + str(i)
	new_game_instance.id = i
	GAMES.add_child(new_game_instance)
	GAMES.move_child(new_game_instance, i)
	new_game_instance.visible = visible_games
	# set Game_Instance position on grid;
	var bounds = new_game_instance.get_node("Bounds")
	var area = bounds.get_node("area")
	var size = area.get_shape().get_rect().size
	var x = (i%grid_dim)*(size.x + 350)
	var y = (floor(i/grid_dim))*(size.y + 350)
	new_game_instance.position = Vector2(x, y)
	# get all (previously onready) vars needed for instance setup
	var bullet_mgr = new_game_instance.get_node("BulletManager")
	var ally_map_pts = new_game_instance.get_node("AllyMapPoints")
	var ally_ai:Director = new_game_instance.get_node("AllyMapDirector")
	var enemy_ai:Director = new_game_instance.get_node("EnemyMapDirector")
	var pathfinding = new_game_instance.get_node("Pathfinding")
	# PARAMETER SETUP 
	ally_ai.communication_count = communication_count
	ally_ai.communication_delay = communication_delay
	enemy_ai.communication_count = communication_count # TODO same as allies?
	enemy_ai.communication_delay = communication_delay # TODO same as allies?
	ally_ai.vision_distance = vision_distance
	ally_ai.vision_angle = vision_angle
	enemy_ai.vision_distance = vision_distance
	enemy_ai.vision_angle = vision_angle
	
	# connect Global Signal bullet fired
	GlobalSignals.bullet_fired.connect(bullet_mgr.handle_bullet_spawned)
	# initialize ally and enemy ai for instance
	var ally_next_positions:Array = ally_map_pts.get_positions()
	var ally_next_positions_rev:Array = ally_map_pts.get_positions()
	ally_next_positions_rev.reverse() # add reverse to loop back through map
	var ally_init_positions = ally_next_positions + ally_next_positions_rev 
	ally_ai.initialize(ally_init_positions, pathfinding)
	enemy_ai.initialize([], pathfinding)
	# connect state flush to output handler
	new_game_instance.game_state.connect("state_flush",flush_game_instance_state)
	new_game_instance.set_flush_state(flush_state)
	return new_game_instance


func setup():
	await get_tree().physics_frame
	set_physics_process(true)
	outputhandler.init(instance_num)  # initialize file output handler
	for i in range(instance_num):
		setup_instance(i)
	gui.set_player(player)

func flush_game_instance_state(filename, data):
	outputhandler.write_to_file(filename, data)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		handle_end_of_game()

func handle_end_of_game():
	outputhandler.write_buffered_data()
	outputhandler.write_to_file("main", "games timed out")
	for game_instance:GameInstance in GAMES.get_children():
		game_instance.game_state.state_update(true,"", true) # store save on timeout
	get_tree().quit()

func _on_time_out_timeout():
	handle_end_of_game()


func _on_open_file_files_selected(paths):
	for path in paths:
		var file = FileAccess.open(path, FileAccess.READ)
		var filename:String = path.get_file()
		var instance_id = int(filename.split("_")[2])
		if instance_id >= instance_num:
			print("ERROR! trying to load instance that doesn't exist")
			print("\tplease rerun with at least ", instance_id+1, " instances")
			continue # in case we try to load a higher instance then exists
		remove_game_instance(instance_id)
		var content = file.get_as_text()
		var contentDict = JSON.parse_string(content)
		var g = setup_instance(instance_id) # and generate a new one
		g.load_game_state(contentDict) # load from contentDict
	GAMES.process_mode = Node.PROCESS_MODE_INHERIT

func remove_game_instance(i):
	var all_games = GAMES.get_children()
	var game_instance:GameInstance = all_games[i]
	game_instance.queue_free() # need to REMOVE old instance!

func _on_open_file_canceled():
	GAMES.process_mode = Node.PROCESS_MODE_INHERIT


func _on_instance_ui_reset_with_instances(count):
	if count > instance_num:
		print("WARNING! unexpected behaviour if upscaling...")
	outputhandler.init(count)
	for i in range(instance_num):
		remove_game_instance(i)
	instance_num = count
	for i in range(instance_num):
		setup_instance(i)
