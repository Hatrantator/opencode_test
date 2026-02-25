// @name hue_mask
// @category Fragment
// @type Spatial
// @description 

uniform sampler2D hueMaskTexture: hint_default_white;
uniform float hueMaskScale = 64.0;

varying float hue;
varying vec3 hue_rgb;

float hueValue(vec3 node_pos_world, sampler2D map) {
	float hMaskValue = texture(map, (node_pos_world.xz / hueMaskScale)+0.5).r; //+.5 only for mmi
	return hMaskValue;
}

vec3 hueColor(vec3 node_pos_world, sampler2D map) {
	vec3 hMaskValue = texture(map, (node_pos_world.xz / hueMaskScale)+0.5).rgb; //+.5 only for mmi
	return hMaskValue;
}