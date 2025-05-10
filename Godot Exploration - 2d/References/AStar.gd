class_name AStar
extends RefCounted

var NEIGHBOR_DIRECTIONS = [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1)]

# Estimate cost between two grid positions by using Manhattan distance.
func heuristic(a: Vector2i, b: Vector2i):
	return abs(a.x - b.x) + abs(a.y - b.y)

func astar(grid: Grid2D, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var frontier: PriorityQueue = PriorityQueue.new()
	var reached: Dictionary = {}
	
	var start_node = AStarNode.new(start, 0, heuristic(start, goal))
	frontier.push(start_node)
	
	while not frontier.empty():
		var current: AStarNode = frontier.pop()
		
		# Early exit when frontier has found the goal position
		if current.pos == goal:
			# Reconstruct path
			var path: Array[Vector2i] = []
			while current:
				path.append(current.pos)
				current = current.parent
			path.reverse()
			return path
			# TODO maybe not reverse here, so we can just use pop_back to empty out path
		
		reached[current.pos] = true
		
		for direction in NEIGHBOR_DIRECTIONS:
			var neighbor_pos: Vector2i = current.pos + direction
			
			# Grid Bounds Check
			if 0 <= neighbor_pos.x and neighbor_pos.x < grid._size.x and 0 <= neighbor_pos.y and neighbor_pos.y < grid._size.y:
				# Skip neighbor if it is an obstacle or is already reached
				if grid.get_tile(neighbor_pos).val != 0 or neighbor_pos in reached.keys():
					continue
				
				var g = current.g_cost + 1
				var h = heuristic(neighbor_pos, goal)
				
				var neighbor_node: AStarNode = AStarNode.new(neighbor_pos, g, h, current)
				
				# Check frontier for same node with a lower f_cost.
				# Skip insertion of neighbor if it is already in the frontier
				var skip = false
				for n in frontier._data:
					if n.pos == neighbor_pos and n.val <= neighbor_node.val:
						skip = true
						break
				
				if not skip:
					frontier.push(neighbor_node)
				
	return [] # No path was found

class AStarNode extends HeapNode:
	var g_cost: int
	var h_cost: int
	var parent: AStarNode
	
	func _init(pos: Vector2i, g: int, h: int, parent: AStarNode = null) -> void:
		self.pos = pos
		self.g_cost = g
		self.h_cost = h
		self.val = g + h
		self.parent = parent
