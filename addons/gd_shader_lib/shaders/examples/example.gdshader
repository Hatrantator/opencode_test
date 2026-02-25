shader_type spatial;

#include "res://addons/gd_shader_lib/shaders/includes/color_modifier.gdshaderinc"
#include "res://addons/gd_shader_lib/shaders/includes/fresnel_modifier.gdshaderinc"
#include "res://addons/gd_shader_lib/shaders/includes/quadoffset_modifier.gdshaderinc"

void fragment() {
	//includes color modifier effect
	vec3 color = apply_color_strength(gdslColor);
	ALBEDO = color;

	//includes fresnel effect
	vec3 fresnelEmission = fresnelGlow(fresnelAmount,fresnelStrength,fresnelColor.rgb, NORMAL, VIEW);
	float fresnelBasic = fresnel(fresnelAmount, NORMAL, VIEW);
	//ALBEDO += fresnelBasic;
	ALBEDO += fresnelEmission;
	EMISSION = fresnelEmission;
}

void vertex() {
	VERTEX += offset_vertex(UV, MODELVIEW_MATRIX);
}