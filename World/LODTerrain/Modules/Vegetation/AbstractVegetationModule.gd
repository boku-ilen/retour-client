extends Module

#
# This module can be used for any vegetation. It efficiently renders this using a particle shader.
# The area can be filled with multiple different plants using a distribution image.
#

export var num_layers = 1
export var my_vegetation_layer = 4
export(Mesh) var particle_mesh_scene

var particles_scene = preload("res://World/LODTerrain/Modules/Util/HeightmapParticles.tscn")
var LODS = Settings.get_setting("herbage", "rows-at-lod")

var result
var vegetation_layer_data

func _ready():
	for i in range(0, num_layers):
		var instance = particles_scene.instance()
		instance.name = String(i)
		instance.set_mesh(particle_mesh_scene)
		add_child(instance)
	
	# First, get the splatmap
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_splat_data", []))
	
func get_splat_data(d):
	var true_pos = tile.get_true_position()

	result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])

	if result and result.has("ids"):
		vegetation_layer_data = ServerConnection.get_json("/vegetation/%d/%d" % [result.get("ids")[0], my_vegetation_layer])
		
	make_ready()

func _on_ready():
	if result:
		construct_vegetation(result.get("path_to_splatmap"), result.get("ids"))
	
func construct_vegetation(splat_path, splat_ids):
	if LODS.has(String(tile.lod)):
		var node = 0
		var steps = 0
		
		for id in splat_ids:
			if steps >= num_layers:
				break
			
			var nd = get_node(String(node))
		
			nd.set_rows(LODS[String(tile.lod)])
			nd.set_spacing(tile.size / LODS[String(tile.lod)])
			
			if node > num_layers - 1: break
			set_parameters([nd, splat_path, id, node])
			
			node += 1
			steps += 1
		
func set_parameters(data):
	if not vegetation_layer_data or vegetation_layer_data.has("Error") or not vegetation_layer_data.get("path_to_spritesheet"):
		logger.error("Could not get vegetation!");
		return
	
	var distribution = CachingImageTexture.get(vegetation_layer_data.get("path_to_distribution"))
	var spritesheet = CachingImageTexture.get(vegetation_layer_data.get("path_to_spritesheet"))
	var distribution_pixels_per_meter = vegetation_layer_data.get("distribution_pixels_per_meter")
	var splatmap = CachingImageTexture.get(data[1])
	var heightmap = tile.get_texture_recursive("dhm", tile.get_osm_zoom(), 0)
	
	heightmap.flags = 4  # Enable filtering for smooth slopes
	
	var sprite_count = vegetation_layer_data.get("number_of_sprites")
	
	data[0].material_override.set_shader_param("pos", translation)
	data[0].material_override.set_shader_param("spritesheet", spritesheet)
	data[0].material_override.set_shader_param("distribution", distribution)
	data[0].material_override.set_shader_param("sprite_count", sprite_count)
	data[0].material_override.set_shader_param("distribution_pixels_per_meter", distribution_pixels_per_meter)
	
	data[0].process_material.set_shader_param("tile_pos", translation)
	data[0].process_material.set_shader_param("splatmap", splatmap)
	data[0].process_material.set_shader_param("heightmap", heightmap)
	data[0].process_material.set_shader_param("id", data[2])
	
	tile.set_heightmap_params_for_obj(data[0].process_material)
	tile.set_heightmap_params_for_obj(data[0].material_override)