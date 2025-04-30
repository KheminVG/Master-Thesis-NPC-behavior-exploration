extends Node2D
@onready var state_chart: StateChart = $StateChart

func _ready() -> void:
	state_chart.set_expression_property.call_deferred("x", 0)

func _on_assign_x_taken() -> void:
	state_chart.set_expression_property("x", 1)


func _on_input_event_lifeline_state_entered() -> void:
	state_chart.send_event("input0")
