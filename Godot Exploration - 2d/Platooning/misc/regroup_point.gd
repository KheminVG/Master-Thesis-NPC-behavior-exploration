extends Sprite2D
class_name RegroupPoint

signal group
signal explore

@export var _team: String = "ALLY"

func get_team() -> String:
	return self._team

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("group"):
		self.group.emit()
	
	if event.is_action_pressed("explore"):
		self.explore.emit()

func _request_group() -> void:
	self.group.emit()
