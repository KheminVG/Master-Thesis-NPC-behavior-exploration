class_name PriorityQueue
extends RefCounted

var _data: Array[HeapNode] = []

func push(el: HeapNode) -> void:
	self._data.push_back(el)
	var new_el_idx: int = self._data.size() - 1
	self._up_heap(new_el_idx)

func pop() -> HeapNode:
	if self.empty():
		return null
	
	var result: HeapNode = self._data.pop_front()
	if not self.empty():
		self._data.push_front(self._data.pop_back())
		self._down_heap(0)
	return result

func empty() -> bool:
	return self._data.is_empty()

func _get_parent(index: int) -> int:
	return (index - 1) / 2

func _get_left_child(index: int) -> int:
	return 2 * index + 1

func _get_right_child(index: int) -> int:
	return 2 * index + 2

func _swap(a_idx: int, b_idx: int) -> void:
	var a = self._data[a_idx]
	var b = self._data[b_idx]
	
	self._data[a_idx] = b
	self._data[b_idx] = a

func _up_heap(index: int) -> void:
	var parent_idx = self._get_parent(index)
	if self._data[index].ge(self._data[parent_idx]):
		return
	self._swap(index, parent_idx)
	self._up_heap(parent_idx)

func _down_heap(index: int) -> void:
	var left_idx = self._get_left_child(index)
	var right_idx = self._get_right_child(index)
	
	var smallest: int = index
	var size: int = self._data.size()
	
	if right_idx < size and self._data[right_idx].lt(self._data[smallest]):
		smallest = right_idx
	
	if left_idx < size and self._data[left_idx].lt(self._data[smallest]):
		smallest = left_idx
	
	if smallest != index:
		self._swap(index, smallest)
		self._down_heap(smallest)
