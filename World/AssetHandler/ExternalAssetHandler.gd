extends "res://World/AssetHandler/AbstractAssetHandler.gd"


#
# Asset handler for assets which are loaded from an external DSCN file.
#


export(int) var render_layers = 4

var dscn_scene = preload("res://addons/dscn_io/DSCN_Runtime_Node.gd")


func _ready():
	update_interval = 2  # TODO: Setting


# Abstract function which returns the result (a list of assets) of the specific request being implemented.
func _get_server_result():
	var player_pos = PlayerInfo.get_true_player_position()
	# FIXME: this should be done by geodot in the future
	var result = "" # ServerConnection.get_json("/assetpos/get_near/by_assettype/%s/%d.0/%d.0.json"
	 # % [asset_type_id, -player_pos[0], player_pos[2]], false)
	
	if result and result.has("assets"):
		return result["assets"]
	else:
		return null


# Abstract function for getting the position of one asset in the result.
# Must be implemented for moving assets because different server responses have different formats of their data.
func _get_asset_position_from_response(asset_id):
	return [_result[asset_id]["position"][0], _result[asset_id]["position"][1]]


# Abstract function which instances the asset with the given asset_id.
func _spawn_asset(instance_id):
	var asset = _result[instance_id]
	
	# TODO: Remove absolute path once landscapelab-server issue #4 is fixed
	var name_path = "C:/landscapelab-dev/landscapelab-server/buildings/importable/" + asset["asset_name"] + ".glb.dscn"

	var dscn_node = dscn_scene.new()
	
	# Add a node which will be the root of the new asset 
	var asset_root = GroundedSpatial.new()
	asset_root.name = instance_id
	
	# Turn the absolute webmercator position from the server response into a relative local
	#  position at the correct height
	var abs_pos = [-asset["position"][0], asset["position"][1]]
	var local_pos = Offset.to_engine_coordinates(abs_pos)
	var local_pos_3d = Vector3(local_pos.x, 0, local_pos.y)
	
	asset_root.transform.origin = local_pos_3d
	asset_root.add_to_group("SpatialShifting")
	
	add_child(asset_root)
	
	# Load the DSCN file into the asset_root
	asset_root.add_child(dscn_node)
	dscn_node.filepath = name_path
	dscn_node.path_to_node = asset_root.get_path()
	dscn_node.import_dscn()
	
	# Set the VisualLayer of the newly imported Asset
	set_render_layers(asset_root, render_layers)
	
	return true


# Set the render layers of a node and all its children to the specified layer
# TODO: Is there a faster / more elegant way to do this?
func set_render_layers(node, layer):
	if node is VisualInstance:
		node.layers = layer
	
	for child in node.get_children():
		set_render_layers(child, layer)
