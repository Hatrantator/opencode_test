shader_type spatial;

render_mode cull_back, depth_draw_opaque;// vertex_lighting;

#include "res://src/Resources/Shader/includes/custom_method_library.gdshaderinc"
#include "res://src/Resources/Shader/includes/world_environment.gdshaderinc"

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

void vertex(){
	world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
	VERTEX.y = get_height(world_vertex);
	
	vec3 clipmap_vertex = world_vertex - we_player_position;
	float lod = true_round(max(abs(clipmap_vertex.x), abs(clipmap_vertex.z))/we_partition_length) * we_lod_step;
	float subdivision_length = min(pow(2,lod), we_partition_length);
	vec3 fraction = fract((VERTEX + we_partition_length / 2.0) / subdivision_length);
	if (fraction.z == 0.5){
		VERTEX.y = mix(
			get_height(world_vertex - vec3(0, 0, fraction.z * subdivision_length)), 
			get_height(world_vertex + vec3(0, 0, (1.0-fraction.z) * subdivision_length)), 
			fraction.z
		);
	}

	node_pos = NODE_POSITION_WORLD;
	texture_position = get_texture_position(world_vertex, we_height_map, 1.0);
	//texture_position = (world_vertex.xz)/float(textureSize(we_height_map,0).x) + 0.5;
	cloud = get_cloud_attenuation(texture_position);
}

void fragment() {
	NORMAL_MAP = texture(we_normal_map,texture_position).rgb;
	ALBEDO = get_world_albedo(texture_position, UV);
	NORMAL = get_world_normal(texture_position, UV);
}

void light() {
	// multiply directional light with the cloud texture - only affects sunlight
	vec3 custom_light = LIGHT;
	// Attenuation.
	float attenuation = 1.0f;
	if (use_attenuation) {
		if (LIGHT_IS_DIRECTIONAL) { // DirectionalLight3D
		//attenuation = ATTENUATION * (step(0.5, cloud));
		attenuation = ATTENUATION * smoothstep(we_cloud_intensity, min(we_cloud_intensity + 0.15, 1.0), cloud);
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