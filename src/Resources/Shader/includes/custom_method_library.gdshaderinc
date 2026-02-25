//#include "res://src/Resources/Shader/includes/custom_method_library.gdshaderinc"

float true_round(float value){
	return floor(value + 0.5);
}

// returns the texture position - has to be used as UV for clipmap-textures.
// uv_mult must be used if we use 2 different resolutions in tandem:
// tex1 = 1024, uv_mult =  1.0 | tex2 = 4096, uv_mult = 4.0
//calc world_vertex:
//vec3 world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
vec2 get_texture_position(vec3 world_vertex, sampler2D map, float uv_mult) {
	vec2 texture_position = (world_vertex.xz/float(textureSize(map,0).x) + 0.5) * uv_mult;
	return texture_position;
}

float split_specular(float specular) {
	return step(0.5f, specular);
}