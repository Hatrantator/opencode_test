//#include "res://src/Resources/Shader/includes/world_environment.gdshaderinc"

//Generic
global uniform float we_partition_length;
global uniform vec3 we_player_position;
global uniform float we_lod_step;

//Height
global uniform sampler2D we_height_map: hint_default_black;
global uniform float we_height_amplitude;

float get_height(vec3 vertex){
	vec2 heightmap_position  = (vertex.xz)/float(textureSize(we_height_map,0).x) + 0.5;
	return texture(we_height_map, heightmap_position ).r * we_height_amplitude;
}

//Normal Map
global uniform sampler2D we_normal_map: hint_normal;

//Albedo
//splatmaps
global uniform sampler2D we_splat_r: hint_default_black;//, filter_nearest;
global uniform sampler2D we_splat_g: hint_default_black;//, filter_nearest;
global uniform sampler2D we_splat_b: hint_default_black;//, filter_nearest;
global uniform sampler2D we_splat_k: hint_default_black;//, filter_nearest;
uniform bool use_splatmaps = false;
uniform sampler2D tex_red :hint_default_black, repeat_enable, filter_nearest;
uniform sampler2D tex_green: hint_default_black, repeat_enable, filter_nearest;
uniform sampler2D tex_blue : hint_default_black, repeat_enable, filter_nearest;
uniform sampler2D tex_black : hint_default_black, repeat_enable, filter_nearest;
uniform sampler2D normal_red :hint_default_black, repeat_enable, filter_nearest;
uniform sampler2D normal_green: hint_default_black, repeat_enable, filter_nearest;
uniform sampler2D normal_blue : hint_default_black, repeat_enable, filter_nearest;
uniform sampler2D normal_black : hint_default_black, repeat_enable, filter_nearest;

vec3 get_world_albedo(vec2 texture_position, vec2 uv) {
	if (use_splatmaps) {
		float r_weight = texture(we_splat_r, texture_position).r;
		float g_weight = texture(we_splat_g, texture_position).r;
		float b_weight = texture(we_splat_b, texture_position).r;
		float k_weight = texture(we_splat_k, texture_position).r;

		vec4 tex_r = texture(tex_red, uv);
		vec4 tex_g = texture(tex_green, uv);
		vec4 tex_b = texture(tex_blue, uv);
		vec4 tex_k = texture(tex_black, uv);

		vec3 layered = tex_k.rgb;
		if (r_weight > 0.0) layered = tex_r.rgb;
		if (g_weight > 0.0) layered = tex_g.rgb;
		if (b_weight > 0.0) layered = tex_b.rgb;
		return layered;
	} else {
		return vec3(0.0);
	}
}

vec3 get_world_normal(vec2 texture_position, vec2 uv) {
	if (use_splatmaps) {
		float r_weight = texture(we_splat_r, texture_position).r;
		float g_weight = texture(we_splat_g, texture_position).r;
		float b_weight = texture(we_splat_b, texture_position).r;
		float k_weight = texture(we_splat_k, texture_position).r;

		vec4 tex_r = texture(normal_red, uv);
		vec4 tex_g = texture(normal_green, uv);
		vec4 tex_b = texture(normal_blue, uv);
		vec4 tex_k = texture(normal_black, uv);

		vec3 layered = tex_k.rgb;
		if (r_weight > 0.0) layered = tex_r.rgb;
		if (g_weight > 0.0) layered = tex_g.rgb;
		if (b_weight > 0.0) layered = tex_b.rgb;
		layered = normalize(layered * 2.0 - 1.0); // Convert from [0, 1] to [-1, 1]
		return layered;
	} else {
		return vec3(0.0, 1.0, 0.0);
	}
}

//Weather
global uniform float we_wind_speed; // Speed of cloud scrolling and Vertex wind
global uniform vec2 we_wind_direction; // Direction of the wind
global uniform sampler2D we_cloud_map : hint_default_black, repeat_enable;
global uniform float we_cloud_intensity; // Intensity of the cloud shadows

const float SMOOTHING_FACTOR = 0.1; // Add a smoothing factor (lower values = smoother transitions)
uniform vec2 smoothed_wind_direction = vec2(0.0, 0.0);
uniform float smoothed_wind_speed = 0.5;

vec2 get_wind_uv_vertex(vec2 node_pos_worldxy, vec2 uv) {
    vec2 wind_uv = vec2(sin(node_pos_worldxy.x + TIME * 1.25 + uv.y) * ( 1.0 - uv.y) * (we_wind_speed * 3.0), cos(node_pos_worldxy.y + TIME * 0.45 + uv.y) * ( 1.0 - uv.y) * (we_wind_speed * 3.0 - 0.05));
    return wind_uv;
}
vec2 get_smoothed_wind_direction(vec2 current_direction) {
    // Smoothly interpolate the wind direction
    return mix(smoothed_wind_direction, current_direction, SMOOTHING_FACTOR);
}
float get_smoothed_wind_speed(float current_speed) {
    // Smoothly interpolate the wind speed
    return mix(smoothed_wind_speed, current_speed, SMOOTHING_FACTOR);
}
float get_cloud_attenuation(vec2 texture_position) {
	float attenuation = texture(we_cloud_map, texture_position).r;
	return attenuation;
}