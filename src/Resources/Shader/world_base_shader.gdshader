shader_type spatial;

render_mode cull_disabled, depth_draw_opaque;// vertex_lighting;



#include "res://src/Resources/Shader/custom_light.gdshaderinc"
#include "res://src/Resources/Shader/weather.gdshaderinc"
#include "res://src/Resources/Shader/world_texture_coord.gdshaderinc"
#include "res://src/Resources/Shader/albedo_mask.gdshaderinc"

#define TOP_BOTTOM_COLOR


//fragment shader:
uniform vec4 albedo : source_color = vec4(1.0f);
uniform sampler2D albedo_mask : hint_default_black; // this works as a global mask for the albedo color, stretched over all the gridmap
uniform bool use_albedo_texture = false;
uniform sampler2D albedo_texture_1 : hint_default_black;
#ifdef TOP_BOTTOM_COLOR
uniform vec4 albedo_2 : source_color = vec4(1.0f);
uniform sampler2D albedo_texture_2 : hint_default_black;
#endif
uniform bool use_normal = false;
uniform sampler2D normal_texture_1 : hint_default_black;
uniform sampler2D normal_texture_2 : hint_default_black;


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



varying vec3 node_pos;
varying vec3 world_vertex;
varying vec3 base_vertex;
varying vec2 texture_position;
varying float cloud;
varying vec3 instance_origin;

void vertex() {
	world_vertex = VERTEX + MODEL_MATRIX[3].xyz; //if objects are rotated, VERTEX must be excluded from the world position
	node_pos = NODE_POSITION_WORLD;
	texture_position = get_texture_uv_grid_map(world_vertex, cloud_texture);
	cloud = get_cloud_fragment_grid_map(world_vertex);

}

void fragment() {
	if (use_albedo_texture) {
		ALBEDO = texture(albedo_texture_1, UV).rgb;
	} else {
		ALBEDO = albedo.rgb;
	}
    #ifdef TOP_BOTTOM_COLOR
    if (use_albedo_texture) {
        vec3 albedo_1 = texture(albedo_texture_1, UV).rgb;
        vec3 albedo_2 = texture(albedo_texture_2, UV).rgb;
		ALBEDO = get_top_albedo(VERTEX.y, albedo_1, get_albedo(node_pos, albedo_2));
	} else {
        ALBEDO = get_top_albedo(VERTEX.y, vec3(0.0, 0.0, 0.0), get_albedo(node_pos, albedo.rgb));
	}
    #endif
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