extends CharacterBody2D

enum State {BOUNCING, DRAGGING, SELECTED}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var _radius: float = 0.0
var _speed: float = 250.0
var _direction: Vector2 = Vector2(1.0, 0.0)

var white: Color = Color.WHITE
var red: Color = Color.RED
var yellow: Color = Color.YELLOW

var current_color: Color = Color.BLACK : set = set_color, get = get_color
var previous_color: Color = Color.BLACK
var mouse_inside: bool = false

func _ready() -> void:
	self.current_color = white
	self._radius = collision_shape.shape.radius
	self._direction = get_random_direction()
	self.velocity = self._direction * self._speed
	
	# Initialize logic to detect if mouse is inside ball.
	self.mouse_inside = false
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)

func _draw() -> void:
	draw_circle(Vector2(0.0, 0.0), self._radius, self.current_color)

func _input(event: InputEvent) -> void:
	if self.mouse_inside and event.is_action_pressed("MMB"):
		self.queue_free()
	
	if self.mouse_inside and event.is_action_pressed("LMB"):
		if self.current_color == red:
			self.set_color(yellow)
		if self.current_color == white:
			self.set_color(red)
	
	if self.mouse_inside and event.is_action_released("LMB"):
		if self.current_color == yellow:
			self.set_color(white)
	
	if self.current_color == yellow and event is InputEventMouseMotion:
		self.velocity = event.velocity

func _physics_process(delta: float) -> void:
	match current_color:
		# A white colored ball is in a BOUNCING state
		Color.WHITE:
			var motion: Vector2 = self.velocity * delta
			var collision = move_and_collide(motion)

			if collision:
				self.velocity = self.velocity.bounce(collision.get_normal())
				motion = self.velocity * delta
				move_and_collide(motion)
		
		# A yellow colored ball is in a DRAGGING state.
		Color.YELLOW:
			# In the DRAGGING state, the ball will follow the mouse.
			self.global_position = get_global_mouse_position()
		
		# A red colored ball is in a SELECTED state.
		Color.RED:
			# In the SELECTED state, a ball will stop moving. It can still be collided with.
			pass

func get_color() -> Color:
	return current_color

func set_color(new_color: Color):
	if current_color == new_color:
		return # early exit if no change needed
	previous_color = current_color
	current_color = new_color
	queue_redraw()

func get_random_direction() -> Vector2:
	var new_direction: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	return new_direction.normalized()

func _on_mouse_entered() -> void:
	self.mouse_inside = true

func _on_mouse_exited() -> void:
	self.mouse_inside = false
