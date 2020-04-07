extends Module

#
# Implementation of an Asset Handler for linear assets such as streets.
#


export(PackedScene) var path_scene

var shapefile_path = GeodataPaths.get_absolute_with_ending("infrastructure")
var max_lines = 100


func _get_line_array():
	var true_pos = tile.get_true_position()
	var size = tile.size
	
	return Geodot.get_lines_near_position(shapefile_path, -true_pos[0] - size / 2, true_pos[2] + size / 2, size, max_lines)


func init(data=null):
	_get_all_lines()
	
	_done_loading()


func _get_all_lines():
	var lines = _get_line_array()
	var reset = get_node("TransformReset")
	
	for line in lines:
		reset.add_child(_get_path_node_for_line(line))


func _get_path_node_for_line(line):
	var curve = line.get_offset_curve3d(Offset.x, 0, -Offset.z) as Curve3D
	var drawer = path_scene.instance() as LinearDrawer
	
	drawer.set_curve(curve)
	drawer.set_width(float(line.get_attribute("WIDTH")))
	drawer.set_height(0.5)
	drawer.put_points_on_ground()
	drawer._set_tilts()
	
	return drawer
