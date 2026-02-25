// @name Color Modifier
// @category Fragment
// @type Spatial
// @description Multiplies Color with a factor


// Optional source_color
uniform vec3 gdslColor : source_color = vec3(1.0, 1.0, 1.0);
// Optional Color Channel Curve
uniform sampler2D gdslCurve;

// 1.0 = original
// <1.0 = darker
// >1.0 = lighter
uniform float gdslColorStrength : hint_range(0.0, 2.0) = 1.0;

// returns modified color
vec3 apply_color_strength(vec3 baseColor) {
	return baseColor * gdslColorStrength;
}

vec3 apply_color_curve(vec3 inColor, vec2 uv) {
	float rgb_curve_color_r = texture(gdslCurve, vec2(inColor.r, 0.0)).r;
	float rgb_curve_color_g = texture(gdslCurve, vec2(inColor.g, 0.0)).r;
	float rgb_curve_color_b = texture(gdslCurve, vec2(inColor.b, 0.0)).r;
	vec3 outColor = vec3(rgb_curve_color_r, rgb_curve_color_g, rgb_curve_color_b);
	return outColor;
}
