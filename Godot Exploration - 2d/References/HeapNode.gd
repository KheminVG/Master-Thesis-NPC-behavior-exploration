class_name HeapNode
extends RefCounted

var position: Vector2i
var val

func _init(position: Vector2i, value) -> void:
	self.position = position
	self.val = value

func lt(other: HeapNode) -> bool:
	return self.val < other.val

func ge(other: HeapNode) -> bool:
	return self.val >= other.val
