extends Node

#
# This script allows ImageTextures to be loaded from any path in the filesystem, also outside the project directory.
# It caches every loaded image so that it doesn't load an image from the same path twice.
#

var _path_imagetexture_dict: Dictionary = {}
var _flags = 0

# Returns the image at the given path as an ImageTexture.
# If the image has been loaded before, it is returned from the cache dictionary.
func get(path):
	if !_is_in_dict(path):
		_load_into_dict(path)
		
	return _get_texture_from_dict(path)

# Returs a part of the ImageTexture at the given path. Origin and size are Vector2 with fields between 0 and 1.
# Example: Get the bottom left quarter of an image: Origin = (0, 0.5); Size = (0.5, 0.5)
func get_cropped(path, origin, size):
	if !_is_in_dict(path):
		_load_into_dict(path)
	
	var img = _get_image_from_dict(path)
	
	var rec_origin = Vector2(int(img.get_size().x * origin.x), int(img.get_size().y * origin.y))
	var rec_size = Vector2(int(img.get_size().x * size.x), int(img.get_size().y * size.y))
	
	var new_tex = img.get_rect(Rect2(rec_origin, rec_size))

	var new_tex_texture = ImageTexture.new()
	new_tex_texture.create_from_image(new_tex, _flags)
	
	return new_tex_texture

# Adds the image at the given path to the cache dictionary as an ImageTexture.
func _load_into_dict(path):
	# Load the image from the path and create an ImageTexture from it
	var img = Image.new()
	img.load(path)
	var img_tex = ImageTexture.new()
	img_tex.create_from_image(img, _flags)
	
	# Add to dictionary and return
	_path_imagetexture_dict[path] = [img_tex, img]

# Gets an ImageTexture from the cache dictionary using the given path.
func _get_texture_from_dict(path):
	return _path_imagetexture_dict[path][0]
	
func _get_image_from_dict(path):
	return _path_imagetexture_dict[path][1]

# Returns true if the image at the path is already in the cache dictionary.
func _is_in_dict(path):
	return _path_imagetexture_dict.has(path)
