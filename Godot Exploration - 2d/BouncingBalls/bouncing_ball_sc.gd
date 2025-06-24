extends CharacterBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var state_chart: StateChart = $StateChart

var _radius: float = 0.0
var _speed: float = 250.0
var _direction: Vector2 = Vector2(1.0, 0.0)
var current_color: Color = Color.BLACK

func _draw() -> void:
	draw_circle(Vector2(0.0, 0.0), self._radius, self.current_color)

## Setting some initial variables when entering the Birth state. 
## Is done only once when the ball is first created.
func _on_birth_state_entered() -> void:
	self._radius = collision_shape.shape.radius
	self._direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	self.velocity = self._direction * self._speed

## Destroy the ball
func _on_death_state_entered() -> void:
	self.queue_free()


# ----------------------------------------------------------------------------#
# BOUNCING STATE (White).
func _on_bouncing_state_entered() -> void:
	self.current_color = Color.WHITE
	queue_redraw()


func _on_bouncing_state_processing(delta: float) -> void:
	var motion: Vector2 = self.velocity * delta
	var collision = move_and_collide(motion)

	if collision:
		self.velocity = self.velocity.bounce(collision.get_normal())
		motion = self.velocity * delta
		move_and_collide(motion)


# ----------------------------------------------------------------------------#
# DRAGGING STATE (Yellow).
func _on_dragging_state_entered() -> void:
	self.current_color = Color.YELLOW
	queue_redraw()


func _on_dragging_state_processing(delta: float) -> void:
	self.global_position = get_global_mouse_position()
	self.velocity = Input.get_last_mouse_velocity()


# ----------------------------------------------------------------------------#
# SELECTED STATE (Red).
func _on_selected_state_entered() -> void:
	self.current_color = Color.RED
	queue_redraw()


# ----------------------------------------------------------------------------#
# MouseInside State
func _on_mouse_inside_state_processing(delta: float) -> void:
	if Input.is_action_just_pressed("LMB"):
		state_chart.send_event("left_press")
	
	if Input.is_action_just_released("LMB"):
		state_chart.send_event("left_release")
	
	if Input.is_action_just_pressed("MMB"):
		state_chart.send_event("destroy_ball")


func _on_mouse_entered() -> void:
	state_chart.send_event("mouse_entered")


func _on_mouse_exited() -> void:
	state_chart.send_event("mouse_exited")
