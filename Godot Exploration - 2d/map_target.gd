extends Node2D

signal target_reached

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is BehaviorAgent:
		emit_signal("target_reached")
