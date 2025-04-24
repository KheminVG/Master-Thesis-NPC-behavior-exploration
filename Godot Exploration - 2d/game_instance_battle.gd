extends GameInstance
class_name GameInstanceBattle

var update_time = 0

@export var Bullet:PackedScene
@onready var AllyMapDirector = $AllyMapDirector
@onready var EnemyMapDirector = $EnemyMapDirector
@onready var BulletManager = $BulletManager

# Called when the node enters the scene tree for the first time.
func _ready():
	game_state = GameInstanceBattleState.new(BulletManager)
	game_state.game_instance_name = name # used for flushing to file
	AllyMapDirector.connect("game_over", stop_instance.bind(false))
	EnemyMapDirector.connect("game_over", stop_instance.bind(true))
	for unit:Actor in AllyMapDirector.get_children():
		unit.connect("actor_hit_by", game_state.update_dmg)
		unit.ai.connect("flush_AI_state_sgn", game_state.update_ally_state)
		game_state.add_ally(unit.ai.get_AI_state())
	for unit:Actor in EnemyMapDirector.get_children():
		unit.connect("actor_hit_by", game_state.update_dmg)
		unit.ai.connect("flush_AI_state_sgn", game_state.update_enemy_state)
		game_state.add_enemy(unit.ai.get_AI_state())

func set_flush_state(on):
	game_state.flush = on

func stop_instance(allies_won:bool):
	print("game over in instance: ", name)
	if allies_won:
		$"Game Over/AlliesWon".visible = true
	else:
		$"Game Over/EnemiesWon".visible = true
	game_state.state_update(true, "", false, true) # TODO what if there are still bullets flying?


func _process(delta):
	game_state.update_time += delta

# constructs named dict of id:node for given list of child nodes
func construct_name_dict(child_list):
	var out = {}
	for c:Node in child_list:
		out[c.name] = c
	return out

# takes "(x, y)" and returns (x,y) as Vector2 
func str_to_vec2(input:String):
	var outputstr = input.erase(0) # remove (
	outputstr = outputstr.erase(outputstr.length()-1) # remove )
	var outputlist = outputstr.split(",")
	return Vector2(float(outputlist[0]),float(outputlist[1]))

func load_game_state(newstate):
	print("loading game state")
	var allyData = newstate["allies"]
	var allies = AllyMapDirector.get_children()
	var allies_map:Dictionary = construct_name_dict(allies)
	var enemyData = newstate["enemies"]
	var enemies = EnemyMapDirector.get_children()
	var enemies_map:Dictionary = construct_name_dict(enemies)
	# UPDATING ALLIES
	for ally_update in allyData:
		var ally_id = allyData[ally_update]["id"]
		if ally_id in allies_map: # checks if ally from load exists
			var ally:Actor = allies_map[ally_id]
			# need to reference target if exists
			var target = allyData[ally_update]["target"]
			if target:
				allyData[ally_update]["target"] = enemies_map[target]
			ally.set_state(allyData[ally_update])
	# UPDATING ENEMIES
	for enemy_update in enemyData:
		var enemy_id = enemyData[enemy_update]["id"]
		if enemy_id in enemies_map:
			var enemy:Actor = enemies_map[enemy_id]
			# need to reference target if exists
			var target = enemyData[enemy_update]["target"]
			if target:
				enemyData[enemy_update]["target"] = allies_map[target]
			enemy.set_state(enemyData[enemy_update])
	# UPDATING damage_done AND team_damage
	game_state.state["damage_done"] = newstate["damage_done"]
	game_state.state["team_damage"] = newstate["team_damage"]
	# UPDATING BULLETS
	for b_ind in newstate["bullets"]:
		var bulletData = newstate["bullets"][b_ind]
		var pos_str = bulletData["POS"]
		var pos = str_to_vec2(pos_str)
		var dir_str = bulletData["DIR"]
		var dir = str_to_vec2(dir_str)
		var team = bulletData["TEAM"]
		var newbullet = Bullet.instantiate()
		BulletManager.handle_bullet_spawned(newbullet, pos, dir, team)
	# WRITING LOADED STATE AS CHECK
	game_state.state_update(true, "postload")
	
	

# class that gathers data
# this consists of both the Scoring Metrics:
#	 amount of team damage vs enemy damage; time spent; total distance traversed; trade-off between metrics
# as well as intermediate State (which can be used for scoring metrics too)
# it's not a listener class, we want it to receive data from other sources
class GameInstanceBattleState extends GameState:
	var BulletManager = null
	func _init(BulletManager):
		state = {} # state is dictionary of 'interesting' values
		state["team_damage"] = {"allies": 0, "enemies": 0}  # damage done within team (friendly fire)
		state["damage_done"] = {"allies": 0, "enemies": 0}  # damage done to other team
		state["allies"] = {}
		state["enemies"] = {}
		state["bullets"] = {}
		teams = ["allies", "enemies"]
		self.BulletManager = BulletManager
	
	func add_ally(ally_state):
		self.state["allies"][ally_state.id] = ally_state
	
	func add_enemy(enemy_state):
		self.state["enemies"][enemy_state.id] = enemy_state
	
	func state_update(force=false, suffix="", timeout=false, gameover=false):
		if force:
			# get bullet data
			state["bullets"] = {}
			var b_ind = 0
			for b:Bullet in self.BulletManager.get_children():
				state["bullets"][b_ind] = b.get_state()
				b_ind += 1
		if force or flush:
			self.state["timer"] = update_time
			var filename = game_instance_name + "_" + str(update_time) + suffix
			if timeout:
				filename = game_instance_name + "_" + "TIMEOUT"
			if gameover:
				filename = game_instance_name + "_" + "GAMEOVER"
			state_flush.emit(filename, JSON.stringify(state)) # emit state flush signal TODO every update or only every X?
		
	func update_team_damage(team, damage):
		self.state["team_damage"][team] += damage
		state_update()
	
	func update_damage_done(team, damage):
		self.state["damage_done"][team] += damage
		state_update()
	
	func update_dmg(to_team, from_team, damage):
		if from_team == to_team: # friendly fire
			update_team_damage(teams[from_team], damage)
		else: # regular damage
			update_damage_done(teams[from_team], damage)
	
	func update_ally_state(ally_name, newstate):
		self.state["allies"][ally_name] = newstate
		state_update()
		
	func update_enemy_state(enemy_name, newstate):
		self.state["enemies"][enemy_name] = newstate
		state_update()
