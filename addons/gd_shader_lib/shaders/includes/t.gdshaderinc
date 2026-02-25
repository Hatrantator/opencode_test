// @name t
// @category Fragment
// @type Spatial
// @description 

uniform vec3 gdsl_source_color : source_color = vec3(1.0);
uniform float gdsl_strength : hint_range(0.0, 2.0) = 1.0;

vec3 gdsl_apply(vec3 color) {
	return color * gdsl_strength;
}
