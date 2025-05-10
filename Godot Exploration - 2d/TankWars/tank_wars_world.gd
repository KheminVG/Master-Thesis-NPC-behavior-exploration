extends Node2D
class_name TankWarsInstance

@export var TILE_SIZE: int = 64
@onready var area: CollisionShape2D = $Bounds/area


func get_map_dimensions() -> Dictionary:
	var dimensions: Dictionary = {}
	
	dimensions["size"] = area.get_shape().get_rect().size
	dimensions["tile_size"] = TILE_SIZE
	dimensions["instance_offset"] = position
	
	return dimensions
