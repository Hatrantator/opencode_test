shader_type spatial;

render_mode cull_disabled, depth_draw_opaque;// vertex_lighting;

#include "res://src/Resources/Shader/custom_light.gdshaderinc"
#include "res://src/Resources/Shader/weather.gdshaderinc"
#include "res://src/Resources/Shader/world_texture_coord.gdshaderinc"
#include "res://src/Resources/Shader/albedo_mask.gdshaderinc"


global uniform sampler2D height_map: repeat_disable;
global uniform sampler2D normal_map: hint_normal;
global uniform float height_amplitude;
global uniform vec3 player_position;
global uniform float world_partition_length;
//global uniform float lod_step;
uniform float lod_step = 1.0;

//fragment shader:
//albedo
uniform float alpha_scissor = 0.99f;
uniform vec4 albedo_0 : source_color = vec4(1.0f); //default color
uniform vec4 albedo_1 : source_color = vec4(1.0f); //default color
uniform bool use_albedo_mask = false;
uniform sampler2D albedo_mask : hint_default_black; // this works as a global mask for the albedo color, stretched over all the gridmap
uniform bool use_albedo_texture = true;
uniform vec2 albedo_uv = vec2(1,1);
uniform sampler2D albedo_texture_0 : hint_default_black;
uniform sampler2D albedo_texture_1 : hint_default_black;
//splatmaps
global uniform bool use_splatmaps;
global uniform sampler2D splat_r: hint_default_black, filter_nearest;
global uniform sampler2D splat_g: hint_default_black, filter_nearest;
global uniform sampler2D splat_b: hint_default_black, filter_nearest;
global uniform sampler2D splat_k: hint_default_black, filter_nearest;
uniform bool use_r = false;
uniform bool use_g = false;
uniform bool use_b = true;
uniform bool use_k = false;

//vertex shader:
uniform bool use_billboard = false;
uniform bool wind_sway = false;

//light shader
uniform bool clamp_diffuse_to_max = false;
uniform bool use_attenuation = true;
uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-2.0f, 2.0f) = 0.17f;
uniform float steepness : hint_range(1.0f, 8.0f) = 3.0f;

uniform bool use_specular = false;
uniform float specular_strength : hint_range(0.0f, 1.0f) = 1.0f;
uniform float specular_shininess : hint_range(0.0f, 32.0f) = 16.0f;
uniform sampler2D specular_map : hint_default_black;

uniform bool use_rim = false;
uniform float rim_width : hint_range(0.0f, 16.0f) = 8.0f;
uniform vec4 rim_color : source_color = vec4(1.0f);

uniform bool use_ramp = false;
uniform sampler2D ramp : hint_default_black;

uniform bool use_borders = false;
uniform float border_width = 0.01f;

//new variables
varying vec3 node_pos;
varying vec3 world_vertex;
varying vec3 base_vertex;
varying vec2 texture_position; //tracks texture xz position based on the global vertex position
varying float cloud;

float true_round(float value){
	return floor(value + 0.5);
}

float get_height(vec3 vertex){
	vec2 heightmap_position  = (world_vertex.xz)/float(textureSize(height_map,0).x) + 0.5;
	return texture(height_map, heightmap_position ).r * height_amplitude;
}

void vertex(){
	world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
	VERTEX.y += get_height(world_vertex);

	vec3 clipmap_vertex = world_vertex - player_position;
	float lod = true_round(max(abs(clipmap_vertex.x), abs(clipmap_vertex.z))/world_partition_length) * lod_step;

	float subdivision_length = min(pow(2,lod), world_partition_length);

	vec3 fraction = fract((VERTEX + world_partition_length / 2.0) / subdivision_length);

	if (fraction.z == 0.5){
		VERTEX.y = mix(
			get_height(world_vertex - vec3(0, 0, fraction.z * subdivision_length)),
			get_height(world_vertex + vec3(0, 0, (1.0-fraction.z) * subdivision_length)),
			fraction.z
		);
	}

    if (use_billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
				vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
				vec4(0.0, 1.0, 0.0, 0.0),
				vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
				MODEL_MATRIX[3]);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

		NORMAL = vec3(0.0, 1.0, 0.0);
	}

    if (wind_sway) {
		vec2 wind_vertex =  get_wind_uv_vertex(NODE_POSITION_WORLD.xz, UV);
		VERTEX.x += wind_vertex.x;
		VERTEX.z += wind_vertex.y;
	}

	node_pos = NODE_POSITION_WORLD;
	texture_position = get_texture_position(world_vertex, height_map);
	texture_position = (world_vertex.xz)/float(textureSize(height_map,0).x)  + 0.5;
	cloud = get_cloud_fragment_grid_map(world_vertex);
}

void fragment() {
	//LIGHT_VERTEX.y = VERTEX.y;
	//LIGHT_VERTEX = vec3(0.5,0.0,0.5);

	// TODO: learn LIGHT_VERTEX
	// Offset LIGHT_VERTEX to simulate shifted lighting
	ALBEDO = texture(albedo_texture_0, UV).rgb * albedo_0.rgb;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
	ALPHA = get_alpha(node_pos,albedo_0.a * texture(albedo_texture_0, UV).a);

	if (use_splatmaps) {
		float splat_r_alpha = texture(splat_r, texture_position).r;
		float splat_g_alpha = texture(splat_g, texture_position).r;
		float splat_b_alpha = texture(splat_b, texture_position).r;
		float splat_k_alpha = texture(splat_k, texture_position).r;

		if (use_r) {
			ALPHA *= splat_r_alpha;
		}
		if (use_g) {
			ALPHA *= splat_g_alpha;
		}
		if (use_b) {
			ALPHA *= splat_b_alpha;
		}
		if (use_k) {
			ALPHA *= splat_k_alpha;
		}
	}

}

void light() {
	// multiply directional light with the cloud texture - only affects sunlight
	vec3 custom_light = LIGHT;
	// Attenuation.
	float attenuation = 1.0f;
	if (use_attenuation) {
		if (LIGHT_IS_DIRECTIONAL) { // DirectionalLight3D
		//attenuation = ATTENUATION * (step(0.5, cloud));
		attenuation = ATTENUATION * smoothstep(cloud_intensity, min(cloud_intensity + 0.15, 1.0), cloud);
		}
		else {
			attenuation = ATTENUATION;
		}
	}

	// Diffuse lighting.
	float NdotL = dot(NORMAL, custom_light);
	float diffuse_amount = NdotL + (attenuation - 1.0) + wrap;

	diffuse_amount *= steepness;
	float cuts_inv = 1.0f / float(cuts);
	float diffuse_stepped = clamp(diffuse_amount + mod(1.0f - diffuse_amount, cuts_inv), 0.0f, 1.0f);

	// Calculate borders.
	float border = 0.0f;
	if (use_borders) {
		float corr_border_width = length(cross(NORMAL, custom_light)) * border_width * steepness;
		border = step(diffuse_stepped - corr_border_width, diffuse_amount)
				 - step(1.0 - corr_border_width, diffuse_amount);
	}

	// Apply diffuse result to different styles.
	vec3 diffuse = ALBEDO.rgb * LIGHT_COLOR / PI;
	if (use_ramp) {
		diffuse *= texture(ramp, vec2(diffuse_stepped * (1.0f - border), 0.0f)).rgb;
	} else {
		diffuse *= diffuse_stepped * (1.0f - border);
	}

	if (clamp_diffuse_to_max) {
		// Clamp diffuse to max for multiple light sources.
		DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);
	} else {
		DIFFUSE_LIGHT += diffuse;
	}

	// Specular lighting.
	if (use_specular) {
		vec3 H = normalize(LIGHT + VIEW);
		float NdotH = dot(NORMAL, H);
		float specular_amount = max(pow(NdotH, specular_shininess*specular_shininess), 0.0f)
							    * texture(specular_map, UV).r
								* attenuation;
		specular_amount = split_specular(specular_amount);
		SPECULAR_LIGHT += specular_strength * specular_amount * LIGHT_COLOR;
	}

	// Simple rim lighting.
	if (use_rim) {
		float NdotV = dot(NORMAL, VIEW);
		float rim_light = pow(1.0 - NdotV, rim_width);
		DIFFUSE_LIGHT += rim_light * rim_color.rgb * rim_color.a * LIGHT_COLOR / PI;
	}

}