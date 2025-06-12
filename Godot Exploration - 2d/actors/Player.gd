# This code is borrowed from work by Joshua Moelans
# https://github.com/JoshuaMoelans/Master-Thesis-Godot-exploration (accessed March 2025)
# Originally developed for his master's thesis at the University of Antwerp

extends CharacterBody2D
class_name Player


@export var SPEED:float = 300.0
@onready var collision_shape = $CollisionShape2D
@onready var sprite = $Sprite2D
@onready var health = $Health
@onready var team = $Team
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

signal move_allies(to_position:Vector2)
signal player_health_changed(new_health)

func _ready() -> void:
	collision_shape.disabled = true
	sprite.visible = false
	pass

func _physics_process(delta):
	var movement_dir := Vector2.ZERO
	if Input.is_action_pressed("right"):
		movement_dir.x = 1
	if Input.is_action_pressed("left"):
		movement_dir.x = -1
	if Input.is_action_pressed("up"):
		movement_dir.y = -1
	if Input.is_action_pressed("down"):
		if not Input.is_action_pressed("save"): # avoid moving if trying to save
			movement_dir.y = 1
	if Input.is_action_pressed("reset_scene"):
		get_tree().reload_current_scene()		
		
	movement_dir = movement_dir.normalized()  # make sure speed is normalized
	velocity = movement_dir*SPEED * delta * 50

	move_and_slide()
	look_at(get_global_mouse_position())


func handle_hit():
	health.health -= 20
	print("player hit! ", health.health)
	player_health_changed.emit(health.health)
	
func get_team() -> int:
	return team.team
