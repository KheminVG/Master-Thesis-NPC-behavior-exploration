extends Node2D
@onready var state_chart: StateChart = $StateChart


func _on_init_state_entered() -> void:
	self.state_chart.send_event("input")


func _on_transition_order_init_state_entered() -> void:
	self.state_chart.send_event("event0")


func _on_double_taken() -> void:
	self.state_chart.set_expression_property("x", 2 * self.state_chart.get_expression_property("x"))


func _on_decrease_taken() -> void:
	self.state_chart.set_expression_property("x", self.state_chart.get_expression_property("x") - 2)
