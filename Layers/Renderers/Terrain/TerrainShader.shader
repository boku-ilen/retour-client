shader_type spatial;

// Basic Terrain
uniform sampler2D orthophoto: hint_albedo;
uniform sampler2D heightmap;
uniform float height_scale = 1.0;

// Surface heights
uniform bool has_surface_heights = false;
uniform float surface_heights_start_distance = 800.0;
uniform sampler2D surface_heightmap;

// Land use-based detail textures
uniform sampler2D landuse;
uniform bool has_landuse = false;

uniform sampler2DArray albedo_tex: hint_albedo;
uniform sampler2DArray normal_tex: hint_normal;
uniform sampler2DArray ambient_tex;
uniform sampler2DArray specular_tex;
uniform sampler2DArray roughness_tex;
uniform sampler2DArray ao_tex;

// See Vegetation.get_metadata_texture for details
uniform sampler2D metadata;

uniform sampler2DArray distance_tex: hint_albedo;
uniform sampler2DArray distance_normals: hint_normal;

uniform float normal_scale = 1.0;
uniform float ortho_saturation = 1.5;
uniform float ortho_blue_shift_factor = 0.9;

uniform float size;

varying vec3 camera_pos;
varying vec3 world_pos;
varying float world_distance;

void vertex() {
	world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_distance = length(world_pos.xz);
	
	VERTEX.y = texture(heightmap, UV).r * height_scale;
	
	if (has_surface_heights) {
		float surface_height_factor = float(world_distance > surface_heights_start_distance);
		VERTEX.y += texture(surface_heightmap, UV).r * height_scale * surface_height_factor;
	}
}

// Decrase or increase the color saturation
// Adapted from http://www.alienryderflex.com/saturation.html
vec3 saturate_color(vec3 color, float change) {
	float P = sqrt(color.r * color.r * 0.299
			+ color.g * color.g * 0.587
			+ color.b * color.b * 0.114);
	
	return vec3(P, P, P) + (color - vec3(P, P, P)) * change;
}

vec3 shift_blue(vec3 color, float change) {
	color.b *= change;
	return color;
}

// Workaround for a bug in `texelFetch` - use this instead!
// More info at https://github.com/godotengine/godot/issues/31732
vec4 texelGet ( sampler2D tg_tex, ivec2 tg_coord, int tg_lod ) {
	vec2 tg_texel = 1.0 / vec2(textureSize(tg_tex, 0));
	vec2 tg_getpos = (vec2(tg_coord) * tg_texel) + (tg_texel * 0.5);
	return texture(tg_tex, tg_getpos, float(tg_lod));
}



void fragment() {
	int splat_id = int(round(texture(landuse, UV).r * 255.0));
	
	vec3 metadata_value = texelGet(metadata, ivec2(splat_id, 0), 0).rgb;
	
	float plant_row = metadata_value.r * 255.0;
	float ground_texture_scale = metadata_value.g * 128.0; // FIXME: Move scale to uniform
	float fade_texture_scale = metadata_value.b * 128.0;
	
	if (ground_texture_scale > 0.0 && has_landuse && world_distance < 20.0) { // FIXME: Move this threshold to uniform
		vec3 scaled_uv = vec3(UV * size / ground_texture_scale, plant_row);
		
		ALBEDO = texture(albedo_tex, scaled_uv).rgb;
		NORMALMAP = texture(normal_tex, scaled_uv).rgb;
		AO = texture(ambient_tex, scaled_uv).r;
		SPECULAR = texture(specular_tex, scaled_uv).r;
		ROUGHNESS = texture(roughness_tex, scaled_uv).r;
	} else {
		vec3 blue_shifted_sample = shift_blue(texture(orthophoto, UV).rgb, ortho_blue_shift_factor);
		ALBEDO = saturate_color(blue_shifted_sample, ortho_saturation);
	}
}