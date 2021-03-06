extends WorldEnvironment

onready var light = get_node("DirectionalLight")

var clouds_scene = preload("res://addons/volumetric-clouds/CloudRenderer.tscn")

var CLOUDS_ENABLED = Settings.get_setting("sky", "clouds")
var FOG_BEGIN = Settings.get_setting("sky", "fog-begin")
var FOG_END = Settings.get_setting("sky", "fog-end")
var MAX_SUN_INTENSITY = Settings.get_setting("sky", "max-sun-intensity")

var clouds

var current_time = 12
var current_season = 0

# Godot's default values - they look pretty good
var base_horizon_color = Color(139.0 / 255.0, 175.0 / 255.0, 207.0 / 255.0, 1.0) 
var base_top_color = Color(54.0 / 255.0, 80.0 / 255.0, 141.0 / 255.0, 1)

var sun_change_thread = Thread.new()


func _ready():
	# React to time_changed events
	GlobalSignal.connect("time_changed", self, "_on_time_changed")
	GlobalSignal.connect("season_changed", self, "_on_season_changed")
	
	# Set time and season with default values
	# FIXME: Disabled until sun position fetching is reimplemented without server
	#update_time_season()
	update_colors(90, 0)
	
	# Spawn Skycube if setting is on
	if CLOUDS_ENABLED:
		clouds = clouds_scene.instance()
		add_child(clouds)
		
	environment.fog_depth_begin = FOG_BEGIN
	environment.fog_depth_end = FOG_END


func _physics_process(delta):
	pass
	# Make the light stick to the player in order to always show highest detail shadows next to them
	# FIXME: Make the light follow the player, or just add this scene as a child to the player?
	#light.translation = PlayerInfo.get_engine_player_position()


func get_middle_of_season(season): # 0 = winter, 1 = spring, 2 = summer, 3 = fall
	return {day = 1, month = 2 + season * 3, year = 2018}
	# Example: Spring -> 1.5.2018


func set_sun_position_for_seasontime(season, hours):
	logger.debug("setting sun position to season: %s and time: %s" % [season, hours])
	var date = get_middle_of_season(season)
	set_sun_position_for_datetime(hours, date.day, date.month, date.year)


func set_sun_position_for_datetime(hours, day, month, year):
	# TODO: can we replace these placeholder values with the actual ones?
	var position_longitude = 15.1
	var position_latitude = 48.1
	var elevation = 100.1
	
	# FIXME: pysolar will be included with a direct python call in a subprocess of via godot-python
	# var url = "/location/sunposition/%04d/%02d/%02d/%02d/%02d/%f/%f/%f.json" % [year, month, day, floor(hours), floor((hours - floor(hours)) * 60), position_longitude, position_latitude, elevation]
	set_sun_position(45, 45)


func set_sun_position(altitude, azimuth):
	# Godot calls the values latitude and longitude for some reason, 
	# but they are actually equivalent to altitude and azimuth
	environment.background_sky.sun_latitude = altitude
	
	# Longitude must be between -180 and 180
	if azimuth > 180: azimuth -= 360
	environment.background_sky.sun_longitude = azimuth
	
	# Change the directional light to reflect sun change
	light.rotation_degrees = Vector3(-altitude, 180 - azimuth, 0)
	
	# Also pass the direction as a parameter to the clouds - they require it as 
	# the vector the light is pointing at, which is the forward (-z) vector
	if clouds:
		clouds.set_sun_direction(-light.transform.basis.z)
	
	update_colors(altitude, azimuth)


func set_light_energy(new_energy):
	light.light_energy = new_energy
	environment.ambient_light_energy = 0.2 + new_energy * 2.2
	
	if clouds:
		clouds.set_sun_energy(new_energy / MAX_SUN_INTENSITY)


func update_colors(altitude, azimuth):
	var new_horizon_color = base_horizon_color
	var new_top_color = base_top_color
	
	var new_light_energy = MAX_SUN_INTENSITY
	
	if altitude < 20 and altitude > -20: # Sun is close to the horizon
		# Make the horizon red/yellow-ish the closer the sun is to the horizon
		var distance_to_horizon = 1 - abs(altitude) / 20
		var horizon_blend_color = Color(0.7, 0.3, 0, distance_to_horizon)
		
		new_horizon_color = new_horizon_color.blend(horizon_blend_color)
		
		# Make the sky get progressively darker
		var distance_to_black_point = 1 - ((20 + altitude) / 40)
		new_horizon_color = new_horizon_color.darkened(distance_to_black_point)
		
	elif altitude <= -20: # Sun is far down -> make the horizon black
		new_horizon_color = Color(0, 0, 0, 0)
	
	# Also make the top color darker / black when the sun is down
	if altitude < 0 and altitude > -30:
		var distance_to_black_point = abs(altitude) / 30
		new_top_color = base_top_color.darkened(distance_to_black_point)
		new_light_energy = MAX_SUN_INTENSITY - distance_to_black_point * MAX_SUN_INTENSITY
		
	elif altitude <= -30:
		new_top_color = Color(0, 0, 0, 0)
		new_light_energy = 0
	
	# Apply the colors to the sky
	environment.background_sky.ground_horizon_color = new_horizon_color
	environment.background_sky.sky_horizon_color = new_horizon_color
	environment.background_sky.sky_top_color = new_top_color
	
	set_light_energy(new_light_energy)


func _on_time_changed(time):
	current_time = time
	update_time_season()


func _on_season_changed(season):
	current_season = season
	update_time_season()


func update_time_season():
	# Run this in a thread to prevent stutter while waiting for HTTP request
	if sun_change_thread.is_active():
		logger.warning("Attempt to change time/season, but last change hasn't finished - aborting")
		return
	
	sun_change_thread.start(self, "_bg_set_sun_position_for_seasontime", [current_season, current_time])
	#_bg_set_sun_position_for_seasontime([current_season, current_time])


func _bg_set_sun_position_for_seasontime(data): # Threads can only take one argument, so we need this helper function
	set_sun_position_for_seasontime(data[0], data[1])
	call_deferred("end_thread")


func end_thread():
	sun_change_thread.wait_to_finish()
