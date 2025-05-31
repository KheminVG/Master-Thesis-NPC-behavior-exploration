extends Node2D
class_name Communicator

signal send(message: Dictionary)

const DELAY: float = 2.0

@onready var behavior: StateChart = $Behavior

var outgoing: Array = []
var incoming: Array = []

func _ready() -> void:
	self.behavior.set_expression_property.call_deferred("delay", DELAY)


# Method to add message to communicators outgoing channel
func _add_outgoing(message: Dictionary) -> void:
	self.outgoing.append(message)
	self.behavior.send_event("send")


# Method to add message to communicators incoming channel
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
	
	# TODO implement handler of incoming traffic to send data to appropriate component
	match message.tag:
		"map": pass
		"enemy": pass
		"...": pass
