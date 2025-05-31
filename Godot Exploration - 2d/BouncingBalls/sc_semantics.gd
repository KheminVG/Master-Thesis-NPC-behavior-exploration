extends Node2D
@onready var state_chart: StateChart = $StateChart
@onready var got_event1: AtomicState = $StateChart/ParallelState/InternalEventLifeline/RegionReceive1/GotEvent
@onready var got_event2: AtomicState = $StateChart/ParallelState/InternalEventLifeline/RegionReceive2/GotEvent


#-----------------------------------------------------------------------------#
# MemoryProtocol
func _on_assign_x_taken() -> void:
	state_chart.set_expression_property("x", 1)


#-----------------------------------------------------------------------------#
# InputEventLifeline
func _on_input_event_lifeline_state_entered() -> void:
	state_chart.send_event("input0")


#-----------------------------------------------------------------------------#
# InternalEventLifeline
func _on_internal_broadcast_taken() -> void:
	state_chart.send_event("internal0")
