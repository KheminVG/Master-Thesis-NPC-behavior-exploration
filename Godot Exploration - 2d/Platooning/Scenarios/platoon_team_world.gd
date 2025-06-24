extends PlatoonTestInstance
class_name PlatoonTeamInstance


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
