shader_type particles;

uniform float rows = 20;
uniform float spacing = 0.1;
uniform float random_offset = 0;

uniform sampler2D heightmap;
uniform sampler2D noisemap;

uniform vec3 curv_middle = vec3(0.0, 0.0, 0.0);

// Global parameters - will need to be the same in all shaders:
uniform float height_range = 2000;

uniform float subdiv;
uniform float size;
uniform float size_without_skirt;

uniform float RADIUS = 6371000; // average earth radius in meters

// Shrinks and centers UV coordinates to compensate for the skirt around the edges
vec2 get_relative_pos(vec2 raw_pos) {
	float offset_for_subdiv = ((size_without_skirt/(subdiv+1.0))/size_without_skirt);
	float factor = (size / size_without_skirt);
	
	vec2 pos = raw_pos * factor;

	pos.x -= offset_for_subdiv;
	pos.y -= offset_for_subdiv;
	
	pos.x = clamp(pos.x, 0.005, 0.995);
	pos.y = clamp(pos.y, 0.005, 0.995);
	
	return pos;
}

// Gets the absolute height at a given pos without taking the skirt into account
float get_height_no_falloff(vec2 pos) {
	return texture(heightmap, get_relative_pos(pos)).g * height_range;
}

// Gets the required height of the vertex, including the skirt around the edges (the outermost vertices are set to y=0 to allow seamless transitions between tiles)
float get_height(vec2 pos) {
	float falloff = 1.0/(10000.0);
	
	if (pos.x > 1.0 - falloff || pos.y > 1.0 - falloff || pos.x < falloff || pos.y < falloff) {
		return 0.0;
	}
	
	return get_height_no_falloff(pos);
}

void vertex ()
{
	// Get position
	vec3 pos = vec3(0.0, 0.0, 0.0);
	pos.z = float(INDEX);
	pos.x = mod(pos.z, rows);
	pos.z = (pos.z - pos.x) / rows;
	
	// Center
	pos.x -= rows * 0.5;
	pos.z -= rows * 0.5;
	
	// Apply spacing
	pos *= spacing;
	
	// Transform spacing
	pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], spacing) + 0.5;
	pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], spacing) + 0.5;
	
	// apply our height
	pos.y = get_height((pos.xz / size) * -1.0 + vec2(0.5));
	//pos.y = get_height(vec2(0.5, 0.5));
	
	// rotate our transform
	vec3 noise = texture(noisemap, abs(pos.xz) / size + vec2(random_offset)).rgb;

	pos.x += noise.x * (spacing / 2.0 - spacing);
	pos.z += noise.y * (spacing / 2.0 - spacing);

	TRANSFORM[0][0] = cos(noise.z * 3.0);
	TRANSFORM[0][2] = -sin(noise.z * 3.0);
	TRANSFORM[2][0] = sin(noise.z * 3.0);
	TRANSFORM[2][2] = cos(noise.z * 3.0);
	
	// Update position
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y;
	TRANSFORM[3][2] = pos.z;
}