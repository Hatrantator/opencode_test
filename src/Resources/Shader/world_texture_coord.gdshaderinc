
// Returns the texture coordinates for a given world position in a 2D texture map
vec2 get_texture_uv_grid_map(vec3 world_vertex, sampler2D world_map) {
//Calculate world_vertex like this to get the correct position in the world
//vec3 world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
//vec2 node_pos_worldxy = NODE_POSITION_WORLD.xz;
	vec2 texture_position = (world_vertex.xz + 0.25)/float(textureSize(world_map,0).x * 2);
	texture_position += 0.25;
    return texture_position;
}

vec2 get_texture_position(vec3 world_vertex, sampler2D map) {
	vec2 texture_position = (world_vertex.xz + 0.5)/float(textureSize(map,0).x);
	return texture_position;
}