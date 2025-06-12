# This code is borrowed from work by Joshua Moelans
# https://github.com/JoshuaMoelans/Master-Thesis-Godot-exploration (accessed March 2025)
# Originally developed for his master's thesis at the University of Antwerp

extends Node
class_name OutputHandler

@export var write_buffered_game_data = false
var gamesOutput = [] # list containing string output for games
var gamesOutputFileNames = []
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func init(instance_count):
	for i in range(instance_count):
		var instance_file_name = "game_instance_" + str(i) # TODO also add timestamp identifier
		gamesOutputFileNames.append(instance_file_name)
		var file = FileAccess.open("user://logs/" + instance_file_name + ".txt", FileAccess.WRITE) # should create empty file
		gamesOutput.append("")

# writes the given data to the given filename
func write_to_file(filename, data, append=false):
	if not FileAccess.file_exists("user://logs/" + filename + ".txt"):
		var file = FileAccess.open("user://logs/" + filename + ".txt", FileAccess.WRITE) # should create empty file
		file.store_string(data)
		file.close()
	else:
		var access = FileAccess.WRITE
		if append:
			access = FileAccess.READ_WRITE
		var file = FileAccess.open("user://logs/" + filename + ".txt", access)
		if append:
			file.seek_end()
		file.store_string(data)
		file.close()

# writes the given data to the given instance IDs file
func write_to_instance_file(i:int, data:String):
	var instance_file_name = gamesOutputFileNames[i]
	var instance_file = FileAccess.open("user://logs/" + instance_file_name + ".txt", FileAccess.READ_WRITE)
	instance_file.seek_end()
	instance_file.store_string(data)
	instance_file.close()

# writes the given data to the given instance file's buffer
# gets flushed periodically to a file every 5s
func write_to_instance_buffer(i:int, data):
	pass
	#gamesOutput[i] += "\n" + data

# writes buffered data for each instance
func write_buffered_data():
	for i in range(len(gamesOutputFileNames)):
		var data = gamesOutput[i]
		write_to_instance_file(i, data)
		gamesOutput[i] = ""  # reset current instance buffer


# periodically triggers a write of all buffered data
func _on_write_timer_timeout():
	if write_buffered_game_data:
		write_buffered_data()
