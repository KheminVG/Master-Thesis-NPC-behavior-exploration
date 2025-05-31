extends Node2D
@onready var state_chart: StateChart = $StateChart


func _on_init_state_entered() -> void:
	self.state_chart.send_event("input")


func _on_transition_order_init_state_entered() -> void:
	self.state_chart.send_event("event0")
