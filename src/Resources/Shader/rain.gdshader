shader_type spatial;

render_mode unshaded, shadows_disabled, cull_disabled;


#include "res://src/Resources/Shader/weather.gdshaderinc"

uniform sampler2D alpha_mask_texture: repeat_disable;
uniform vec3 color: source_color = vec3(0.0);
uniform vec2 uv_multiplier = vec2(1.0,1.0);

uniform float edge_threshold : hint_range(0.0, 1.0) = 0.1; // Threshold for edge detection

uniform float rotation_z : hint_range(-360.0, 360.0) = 0.0;

varying vec3 world_vertex;

void vertex() {
	// Called for every vertex the material is visible on.

	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

	float angle_z = radians(rotation_z);
	// Construct the rotation matrix for the Z-axis
    mat3 rotation_matrix_z = mat3(
        vec3(cos(angle_z), -sin(angle_z), 0.0),
        vec3(sin(angle_z), cos(angle_z), 0.0),
        vec3(0.0, 0.0, 1.0)
    );

	NORMAL = vec3(0.0, 1.0, 0.0);

	VERTEX = rotation_matrix_z * VERTEX;

	world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv  = UV * uv_multiplier;

	float alpha_mask = texture(alpha_mask_texture,uv).r;
	// normal 0 - Cloud, 1 - No Cloud, so we need to invert it
	float cloud = 1.0 - get_cloud_fragment_grid_map(world_vertex);

	//smoothstep(cloud_intensity, min(cloud_intensity + 0.15, 1.0), cloud)
	ALPHA = alpha_mask;
	ALPHA *= smoothstep(0.6, 0.75, cloud);
	ALBEDO = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
