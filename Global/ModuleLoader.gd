extends Node


var module_path = Settings.get_setting("lod", "module-path")

var modules: Dictionary = {}
var usage_lock = Mutex.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for module in list_files_in_directory(module_path):
		modules[module] = load(module)


func get_instance(module_name):
	usage_lock.lock()
	var instance = modules[module_path + "/" + module_name].instance()
	usage_lock.unlock()
	
	return instance


func list_files_in_directory(path):
	var my_files : Array = []
	var dir := Directory.new()
	
	if dir.open(path) != OK:
		logger.error("Warning: could not open directory: " + path)
		return []
	
	if dir.list_dir_begin(true, true) != OK:
		logger.error("Warning: could not list contents of: " + path)
		return []
	
	var file_name := dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			my_files += list_files_in_directory(dir.get_current_dir() + "/" + file_name)
		else:
			my_files.append(dir.get_current_dir() + "/" + file_name)
	
		file_name = dir.get_next()
	
	return my_files
