// @name blend_modes
// @category Fragment
// @type Spatial
// @description Blend Functions

vec4 blendMultiply(vec4 base, vec4 blend){
	return base * blend;
}
vec4 blendScreen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}
vec4 blendDarken(vec4 base, vec4 blend){
	return min(base, blend);
}
vec4 blendLighten(vec4 base, vec4 blend){
	return max(base, blend);
}
vec4 blendDifference(vec4 base, vec4 blend){
	return abs(base - blend);
}
vec4 blendExclusion(vec4 base, vec4 blend){
	return base + blend - 2.0 * base * blend;
}
vec4 blendOverlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec4 blendHardLight(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec4 blendSoftLight(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}
vec4 blendColorDodge(vec4 base, vec4 blend){
	return base / (1.0 - blend);
}
vec4 blendLinearDodge(vec4 base, vec4 blend){
	return base + blend;
}
vec4 blendColorBurn(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) / blend;
}
vec4 blendLinearBurn (vec4 base, vec4 blend){
	return base + blend - 1.0;
}
