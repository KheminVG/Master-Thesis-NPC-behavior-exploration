extends Node2D
class_name CommunicationChannel

signal send(message: Dictionary)
signal recieve_map(map: Grid2D)

signal attack(target: Vector2)
signal explore
signal regroup(pos: Vector2)

const DELAY: float = 1.0

@onready var behavior: StateChart = $Behavior
@export var channel_name: String = "default"

var outgoing: Array = []
var incoming: Array = []

func _ready() -> void:
	self.behavior.set_expression_property.call_deferred("delay", DELAY)


# Method to add message to communicators outgoing pool
func _add_outgoing(message: Dictionary) -> void:
	self.outgoing.append(message)
	self.behavior.send_event("send")


# Method to add message to communicators incoming pool
func _add_incoming(message: Dictionary) -> void:
	self.incoming.append(message)
	self.behavior.send_event("receive")


#------------------------------------------------------------------------------#
# Sender/Idle State
func _on_sender_idle_state_entered() -> void:
	if not self.outgoing.is_empty():
		self.behavior.send_event("send")


#------------------------------------------------------------------------------#
# Sender/Send State
func _on_send_state_entered() -> void:
	var message = self.outgoing.pop_front()
	self.send.emit(message)


#------------------------------------------------------------------------------#
# Receiver/Idle State
func _on_receiver_idle_state_entered() -> void:
	if not self.incoming.is_empty():
		self.behavior.send_event("receive")


#------------------------------------------------------------------------------#
# Receiver/Process State
func _on_process_state_entered() -> void:
	var message: Dictionary = self.incoming.pop_front()
	
	# Return early if message is not destined for this channel.
	if message.channel != self.channel_name:
		return
	
	match message.tag:
		"map": self.recieve_map.emit(message.data)
		"attack": self.attack.emit(message.data)
		"explore": self.explore.emit()
		"group": self.regroup.emit(message.data)
