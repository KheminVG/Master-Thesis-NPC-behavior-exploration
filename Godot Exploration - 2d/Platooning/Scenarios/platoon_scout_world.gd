extends Node2D
class_name PlatoonTestInstance

@export var TILE_SIZE: int = 64
@onready var area: CollisionShape2D = $Bounds/area


func _ready() -> void:
	# Set up safe point information
	for child in self.get_children():
		if child is Scout:
			for other in self.get_children():
				if other is RegroupPoint and child.get_team() == other.get_team():
					child.scout_strategy.set_safe_point(other.global_position)


func get_map_dimensions() -> Dictionary:
	var dimensions: Dictionary = {}
	
	dimensions["size"] = area.get_shape().get_rect().size
	dimensions["tile_size"] = TILE_SIZE
	dimensions["instance_offset"] = position
	
	return dimensions
