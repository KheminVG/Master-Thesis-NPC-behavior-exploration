class_name MaxHeap
extends PriorityQueue

func _up_heap(index: int) -> void:
	var parent_idx = self._get_parent(index)
	if self._data[parent_idx].ge(self._data[index]):
		return
	self._swap(index, parent_idx)
	self._up_heap(parent_idx)

func _down_heap(index: int) -> void:
	var left_idx = self._get_left_child(index)
	var right_idx = self._get_right_child(index)
	
	var largest: int = index
	var size: int = self._data.size()
	
	if right_idx < size and self._data[largest].lt(self._data[right_idx]):
		largest = right_idx
	
	if left_idx < size and self._data[largest].lt(self._data[left_idx]):
		largest = left_idx
	
	if largest != index:
		self._swap(index, largest)
		self._down_heap(largest)
