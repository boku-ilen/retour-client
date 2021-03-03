extends Configurator


var layer_renderer = preload("res://Layers/LayerRenderer.tscn")
var terrain_renderer = preload("res://Layers/Renderers/Terrain/TerrainRenderer.tscn")
var polygon_renderer = preload("res://Layers/Renderers/Polygon/PolygonRenderer.tscn")
var raster_vegetation_renderer = preload("res://Layers/Renderers/RasterVegetation/RasterVegetationRenderer.tscn")
var object_renderer = preload("res://Layers/Renderers/Objects/ObjectRenderer.tscn")

onready var layer_renderers = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	# There may be some rendered layers which were added before this _ready.
	for layer in Layers.get_rendered_layers():
		add_layer(layer)
	
	# For future layers, use a signal.
	Layers.connect("new_rendered_layer", self, "add_layer")
	Layers.connect("removed_rendered_layer", self, "remove_layer")


func add_layer(layer: Layer):
	var new_layer
	
	if layer.render_type == Layer.RenderType.TERRAIN:
		new_layer = terrain_renderer.instance()
	elif layer.render_type == Layer.RenderType.POLYGON:
		new_layer = polygon_renderer.instance()
	elif layer.render_type == Layer.RenderType.VEGETATION:
		new_layer = raster_vegetation_renderer.instance()
	elif layer.render_type == Layer.RenderType.OBJECT:
		new_layer = object_renderer.instance()
	else:
		# TODO
		new_layer = layer_renderer.instance()
	
	new_layer.layer = layer
	new_layer.name = layer.name
	
	layer_renderers.add_child(new_layer)


func remove_layer(name_to_remove):
	layer_renderers.get_node(name_to_remove).queue_free()