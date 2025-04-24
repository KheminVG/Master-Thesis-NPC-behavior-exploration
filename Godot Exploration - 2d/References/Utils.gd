class_name Utils
extends RefCounted


# takes "(x, y)" and returns (x,y) as Vector2 
func str_to_vec2(input:String):
	var outputstr = input.erase(0) # remove (
	outputstr = outputstr.erase(outputstr.length()-1) # remove )
	var outputlist = outputstr.split(",")
	return Vector2(float(outputlist[0]),float(outputlist[1]))

func path_str_to_vec(input):
	var output = []
	for point in input:
		output.append(str_to_vec2(point))
	return output

func rotate_vec_left(vec: Vector2) -> Vector2:
	var result: Vector2 = Vector2(vec.y, -vec.x)
	return result

func rotate_vec_right(vec: Vector2) -> Vector2:
	var result: Vector2 = Vector2(-vec.y, vec.x)
	return result

func turn_vec_around(vec: Vector2) -> Vector2:
	var result: Vector2 = Vector2(-vec.x, -vec.y)
	return result
