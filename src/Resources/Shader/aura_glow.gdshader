shader_type spatial;

render_mode unshaded, shadows_disabled, cull_disabled;

uniform sampler2D transparency_texture: repeat_disable;
uniform vec3 color: source_color = vec3(0.0);
uniform float min_blinking_alpha: hint_range(0.0, 1.0) = 0.3;
uniform float blink_speed_multiplier = 4.0;
uniform vec2 uv_multiplier = vec2(1.0,1.0);

// Proximity fade parameters
uniform vec3 fade_center = vec3(0.0, 0.0, 0.0); // Reference point for proximity fade
uniform float fade_min_distance = 1.0;          // Minimum distance for full visibility
uniform float fade_max_distance = 64.0;          // Maximum distance for full fade

// Dissolve parameters
uniform sampler2D noise_texture: repeat_enable; // Noise texture for dissolving effect
uniform float dissolve_threshold = 0.5;         // Threshold for dissolving effect
uniform float dissolve_edge_smoothness = 0.1;   // Edge smoothness for dissolving effect

varying vec3 world_vertex;


float remap(float value, float in_min, float in_max, float out_min, float out_max) {
    return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min);
}

void vertex() {
	// Billboard Mode: Y-Billboard
	//MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			//vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			//vec4(0.0, 1.0, 0.0, 0.0),
			//vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			//MODEL_MATRIX[3]);
	//MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

		NORMAL = vec3(0.0, 1.0, 0.0);

	world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
}

void fragment() {
	// custom stretch
	vec2 uv  = UV * uv_multiplier;

	// Sample the transparency texture
	float transparency = texture(transparency_texture,uv).r;

	// Sample the noise texture
    vec2 noise_uv = uv  + vec2(0.0, TIME * 0.1); // Animate the noise
    float noise_value = texture(noise_texture, noise_uv).r;

	// Blinking effect
	float blinking = remap(cos(TIME * blink_speed_multiplier),-1.0, 1.0, min_blinking_alpha, 1.0);

	// Calculate distance from the fragment to the fade center
    float proximity_distance = length(world_vertex - fade_center);

    // Remap the distance to a fade factor (1.0 = fully visible, 0.0 = fully faded)
    float fade = remap(proximity_distance, fade_min_distance, fade_max_distance, 1.0, 0.0);
    fade = clamp(fade, 0.0, 1.0); // Ensure fade is within [0.0, 1.0]

    // Apply the dissolve effect
    float dissolve = smoothstep(dissolve_threshold - dissolve_edge_smoothness, dissolve_threshold + dissolve_edge_smoothness, noise_value) * blinking;

    // Apply proximity fade and blinking to alpha
    ALPHA = transparency * blinking * dissolve;

	ALBEDO = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
