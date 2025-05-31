extends Node2D
class_name PlatoonTestInstance

@export var TILE_SIZE: int = 64
@onready var area: CollisionShape2D = $Bounds/area


func _ready() -> void:
	# Set up information and signal connections for 
	for child in self.get_children():
		if child is Infantry:
			for other in self.get_children():
				if other is Infantry and child.get_team() == other.get_team():
					child.share_map.connect(other._on_map_receive)
				if other is RegroupPoint and child.get_team() == other.get_team():
					child.group_planner.set_regroup_point(other.global_position)
					child.group_planner.reached_regroup.connect(other._request_group)
					other.group.connect(child.infantry_strategy._on_team_group)
					other.explore.connect(child.infantry_strategy._on_team_explore)


func get_map_dimensions() -> Dictionary:
	var dimensions: Dictionary = {}
	
	dimensions["size"] = area.get_shape().get_rect().size
	dimensions["tile_size"] = TILE_SIZE
	dimensions["instance_offset"] = position
	
	return dimensions
