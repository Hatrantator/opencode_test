shader_type spatial;
render_mode world_vertex_coords, cull_disabled, depth_prepass_alpha;// vertex_lighting;

#include "res://addons/gd_shader_lib/shaders/includes/fresnel_modifier.gdshaderinc"
#include "res://addons/gd_shader_lib/shaders/includes/hue_mask.gdshaderinc"
#include "res://addons/gd_shader_lib/shaders/includes/vertex_mask.gdshaderinc"


// tex
uniform sampler2D leaf_albedo_tex : source_color;
uniform sampler2D leaf_normal_tex : hint_normal;
uniform sampler2D leaf_roughness_tex : hint_roughness_r;
uniform vec2 uv_scale = vec2(1.0,1.0);
// albedo
uniform vec4 leaf_albedo_color : source_color = vec4(1.0);
uniform float scissor_threshold : hint_range(0.0, 1.0) = 0.3;
// vertex gradient
uniform vec4 gradient_low_color : source_color = vec4(0.2, 0.4, 0.1, 1.0);
uniform vec4 gradient_high_color : source_color = vec4(0.6, 0.8, 0.2, 1.0);
uniform float height_intensity = 1.0; //color intensity
uniform float gradient_min_y = 0.0;
uniform float gradient_max_y = 1.0;
//wind
uniform float wind_strength = 0.05;
uniform float wind_speed = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.0);
//backlight
uniform vec3 transmission_color : source_color = vec3(0.4, 0.8, 0.3);
uniform float transmission_strength : hint_range(0.0, 5.0) = 1.5;
uniform float transmission_power : hint_range(0.1, 8.0) = 2.0;

void vertex() {
	hue_rgb = hueColor(NODE_POSITION_WORLD, hueMaskTexture);
	visible = is_visible(NODE_POSITION_WORLD, vMaskTexture);
	// Simple world-space wind sway
	float time = TIME * wind_speed;
	float wave = sin(dot((MODEL_MATRIX * vec4(VERTEX,1.0)).xz, wind_direction) + time);
	float height_factor = clamp((VERTEX.y - gradient_min_y) / (gradient_max_y - gradient_min_y), 0.0, 1.0);
	height_factor = 1.0 - UV.y;
	// More movement at leaf tips
	float wind_mask = height_factor;
	VERTEX.xz += wind_direction * wave * wind_strength * wind_mask;
}

void fragment() {
	if (!FRONT_FACING) {NORMAL *= -1.0;}
	vec2 uv = UV * uv_scale;

	vec4 albedo_tex = texture(leaf_albedo_tex, uv);
	vec3 normal_tex = texture(leaf_normal_tex, uv).rgb;
	float roughness_tex = texture(leaf_roughness_tex, uv).r;

	float height_factor = clamp((VERTEX.y - gradient_min_y) / (gradient_max_y - gradient_min_y), 0.0, 1.0);
	height_factor += (1.0 - uv.y) * height_intensity;
    vec3 gradient_color = mix(gradient_low_color.rgb, gradient_high_color.rgb, height_factor);
	vec3 final_albedo = albedo_tex.rgb * leaf_albedo_color.rgb * gradient_color;

	ALBEDO = final_albedo;
	NORMAL_MAP = normal_tex;
	ROUGHNESS = roughness_tex;

	// black to alpha_scissor
	float luminance = dot(albedo_tex.rgb, vec3(0.299, 0.587, 0.114));
	ALPHA = luminance;
	ALPHA_SCISSOR_THRESHOLD = scissor_threshold;

	// backlight
	vec3 view_dir = normalize(VIEW);
	float backlight = pow(
		clamp(dot(-view_dir, NORMAL), 0.0, 1.0),
		transmission_power
	);
	EMISSION += (transmission_color) * backlight * transmission_strength * luminance;
	EMISSION *= hue_rgb;
	if (FRONT_FACING){
	}
	//fresnel
	vec3 fresnelEmission = fresnelGlow(fresnelAmount,fresnelStrength,fresnelColor.rgb, NORMAL, VIEW);
	ALBEDO += fresnelEmission;
	//EMISSION += fresnelEmission;
	
	//hue
	ALBEDO *= hue_rgb;
	
	//if (visible < 0.8) {
		//discard;
	//}
}
