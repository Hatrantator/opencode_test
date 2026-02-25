shader_type spatial;
render_mode blend_mix, depth_draw_opaque,cull_disabled;

#include "res://addons/gd_shader_lib/shaders/includes/color_modifier.gdshaderinc"
#include "res://addons/gd_shader_lib/shaders/includes/fresnel_modifier.gdshaderinc"
#include "res://addons/gd_shader_lib/shaders/includes/quadoffset_modifier.gdshaderinc"

uniform sampler2D alphaTexture;
uniform vec4 alphaTextureColor : source_color;
uniform float alphaThreshold = 0.1;

uniform float clampTop : hint_range(0.0,1.0) = 1.0;
uniform float clampBottom : hint_range(-1.0, 0.0) = 0.0;

void fragment() {
	vec3 color = apply_color_strength(gdslColor);
	
	vec3 albedo = vec3(alphaTextureColor.rgb);
	vec3 fresnelEmission = fresnelGlow(fresnelAmount,fresnelStrength,fresnelColor.rgb, NORMAL, VIEW);
	float fresnelBasic = fresnel(fresnelAmount, NORMAL, VIEW);

	//includes fresnel effect
	//ALBEDO += fresnelBasic;
	//ALBEDO += fresnelEmission;
	ALBEDO = albedo;
	ALPHA = texture(alphaTexture,UV).x;
	ALPHA_SCISSOR_THRESHOLD = alphaThreshold;
	//EMISSION = fresnelEmission;
}

void vertex() {
	VERTEX += offset_vertex(UV, MODELVIEW_MATRIX);
}