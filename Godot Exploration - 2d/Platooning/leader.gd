extends CharacterBody2D
class_name PlayerLeader

var SPEED: int = 200

@export var _team: String = "ALLY"

@onready var behavior: StateChart = $Behavior
@onready var communicator: Communicator = $Communicator
@onready var obstacle_map: ObstacleMap = $ObstacleMap
@onready var indicator_label: Label = $CanvasLayer/Indicator/IndicatorLabel

var safe_point: Vector2 = Vector2(0, 0)
var _map_initialized: bool = false


func set_safe_point(pos: Vector2) -> void:
	self.safe_point = pos

func get_team() -> String:
	return self._team

func _on_receive_map(map: Grid2D) -> void:
	self.obstacle_map.compare_map(map)

func _ready() -> void:
	self.communicator.data_channel.recieve_map.connect(self._on_receive_map)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("sprint"):
		self.SPEED += 100
	if event.is_action_released("sprint"):
		self.SPEED -= 100
	
	if event.is_action_pressed("group"):
		self.behavior.send_event("group")
	
	if event.is_action_pressed("attack"):
		self.behavior.send_event("attack")
	
	if event.is_action_pressed("explore"):
		self.behavior.send_event("explore")

func _process(delta: float) -> void:
	self.look_at(get_global_mouse_position())
	
	var horizontal := Input.get_axis("left", "right")
	var vertical := Input.get_axis("up", "down")
	
	var move_vector = Vector2(horizontal, vertical)
	move_vector = move_vector.normalized()
		
	self.velocity = move_vector * self.SPEED
	move_and_slide()

#-----------------------------------------------------------------------------#
# Commands/Explore State
func _on_explore_state_entered() -> void:
	self.indicator_label.text = "Exploring"
	
	var message = {
		"channel": "command",
		"tag": "explore",
		"data": null
	}
	
	self.communicator.command_channel._add_outgoing(message)


#-----------------------------------------------------------------------------#
# Commands/Attack State
func _on_attack_state_entered() -> void:
	self.indicator_label.text = "Select Target"


func _on_attack_state_processing(delta: float) -> void:
	if Input.is_action_just_pressed("LMB"):
		self.indicator_label.text = "Attacking"
		
		var message = {
			"channel": "command",
			"tag": "attack",
			"data": get_global_mouse_position()
		}
		
		self.communicator.command_channel._add_outgoing(message)
		self.behavior.send_event("end")


#-----------------------------------------------------------------------------#
# Commands/Group State
func _on_group_state_entered() -> void:
	self.indicator_label.text = "Regrouping"
	
	var message = {
		"channel": "command",
		"tag": "group",
		"data": self.safe_point
	}
	
	self.communicator.command_channel._add_outgoing(message)


#-----------------------------------------------------------------------------#
# Commands/Group State
func _on_idle_state_entered() -> void:
	if not self._map_initialized:
		var world: PlatoonTestInstance = self.get_parent()
		var dimensions = world.get_map_dimensions()
		self.obstacle_map.build_empty_map(dimensions)
		self._map_initialized = true
