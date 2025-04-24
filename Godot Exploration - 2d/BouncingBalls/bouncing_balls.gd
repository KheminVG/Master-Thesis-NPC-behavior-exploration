extends Node2D

@onready var ball_preload = preload("res://BouncingBalls/bouncing_ball_sc.tscn")
@onready var balls: Node2D = $Balls

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	self.inputhandler()

func inputhandler() -> void:
	if Input.is_action_just_pressed("RMB"):
		self.create_ball()

func create_ball() -> void:
	var ball_instance = ball_preload.instantiate()
	self.balls.add_child(ball_instance)
	ball_instance.global_position = get_global_mouse_position()
	
