tool
extends Module

#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#

onready var mesh = get_node("MeshInstance")

var ortho
var dhm


func _ready():
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_textures", []))


func _on_ready():
	if ortho:
		mesh.material_override.set_shader_param("tex", ortho)
	
	if dhm:
		mesh.material_override.set_shader_param("heightmap", dhm)


func get_ortho_dhm():
	var response = tile.get_texture_result("raster")
	
	if response:
		if response.has("ortho"):
			ortho = CachingImageTexture.get(response.get("ortho"))
		if response.has("dhm"):
			dhm = CachingImageTexture.get(response.get("dhm"))


func get_textures(data):
	get_ortho_dhm()
	
	make_ready()
