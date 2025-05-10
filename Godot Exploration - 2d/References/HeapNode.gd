class_name HeapNode
extends RefCounted

var pos: Vector2i
var val

func _init(pos: Vector2i, value) -> void:
	self.pos = pos
	self.val = value

func lt(other: HeapNode) -> bool:
	return self.val < other.val

func ge(other: HeapNode) -> bool:
	return self.val >= other.val
