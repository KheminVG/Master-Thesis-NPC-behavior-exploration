extends PlatoonTestInstance
class_name PlatoonLeaderInstance


func _ready() -> void:
	# Set up safe point information and establish communication between leader and teammates
	for child in self.get_children():
		if child is PlayerLeader:
			for other in self.get_children():
				if other is Pawn and other.get_team() == child.get_team():
					other.communicator.data_channel.send.connect(child.communicator.data_channel._add_incoming)
					child.communicator.command_channel.send.connect(other.communicator.command_channel._add_incoming)
				if other is RegroupPoint and other.get_team() == child.get_team():
					child.set_safe_point(other.global_position)
		
		if child is Scout:
			for other in self.get_children():
				if other is RegroupPoint and child.get_team() == other.get_team():
					child.scout_strategy.set_safe_point(other.global_position)
