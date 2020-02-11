extends Viewport


var timer: Timer
var fps: float = 4


func _ready():
	timer = Timer.new()
	timer.set_one_shot(false)
	timer.set_timer_process_mode(0)
	timer.set_wait_time(1.0 / fps)
	timer.set_autostart(false)
	timer.connect("timeout", self, "make_screenshot")
	
	self.add_child(timer)


func _input(event: InputEvent) -> void:
	if event.is_action_released("toggle_imaging_recording"):
		if timer.is_stopped():
			timer.start(0.0)
		else:
			timer.stop()


func make_screenshot():
	# Retrieve the captured image
	var img = get_texture().get_data()
  
	# Flip it on the y-axis (because it's flipped)
	img.flip_y()
	
	# Save to a file, use the current time for naming
	var timestamp = OS.get_datetime()
	var screenshot_filename = "user://videoframe-%d-%d.png" % [OS.get_system_time_msecs(), Session.session_id]
	
	# Medium to low priority - we do want it to save sometime soon, but doesn't have to be immediate
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "save_screenshot", [img, screenshot_filename]), 15)


# Actually save a screenshot - to be run in a thread
func save_screenshot(img_filename_array):
	img_filename_array[0].save_png(img_filename_array[1])
	logger.info("captured screenshot in %s " % [img_filename_array[1]])