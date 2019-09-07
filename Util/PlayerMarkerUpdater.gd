extends Spatial

export(float) var interval = 1  # TODO: Setting?
export(int) var player_marker_asset_id

onready var requester = get_node("RegularServerRequest")


func _ready():
	requester.set_interval(interval)
	requester.set_custom_request_getter(self, "_get_request_string_with_latest_position")
	requester.connect("new_response", self, "_on_new_response")


func _get_request_string_with_latest_position():
	var pos = PlayerInfo.get_true_player_position()
	pos[0] = -pos[0]  # TODO: Generalize
	
	return "/assetpos/create/%d/%d.0/%d.0" % [player_marker_asset_id, pos[0], pos[2]]