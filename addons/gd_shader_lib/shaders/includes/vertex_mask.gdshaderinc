// @name vertex_mask
// @category Vertex
// @type Spatial
// @description

//render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D vMaskTexture: hint_default_white; //gotta be max twice the size of mesh in px
uniform float vMaskThreshold : hint_range(0.0, 1.0) = 0.5;
uniform float vMaskScale = 64.0;

varying float visible;
varying float hasG;

//VERTEX:
//visible = is_visible(VERTEX + MODEL_MATRIX[3].xz);
//if (visible < 0.5) {
//	VERTEX = vec3(0.0);
//}
//FRAGMENT:
//if (visible < 0.5) {
//	discard;
//}
//vec3 world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
//float is_visible(vec3 world_vertex, sampler2D map) {
	//vec2 uv  = (world_vertex.xz + (float(textureSize(map,0).x) / 2.0))/(float(textureSize(map,0).x));
	//float vMaskValue = texture(map, uv).r;
	//return smoothstep(vMaskThreshold, vMaskThreshold+0.05, vMaskValue);
//}

float is_visible(vec3 node_pos_world, sampler2D map) {
	float vMaskValue = texture(map, (node_pos_world.xz / vMaskScale)+0.5).r; //+.5 only for mmi
	return step(vMaskThreshold, vMaskValue);
}

float height_b(vec3 node_pos_world, sampler2D map) {
	float vMaskValue = texture(map, (node_pos_world.xz / vMaskScale)+0.5).b; //+.5 only for mmi
	return vMaskValue;
}

float has_g_value(vec3 node_pos_world, sampler2D map) {
	float vMaskValue = texture(map, (node_pos_world.xz / vMaskScale)+0.5).g; //+.5 only for mmi
	return vMaskValue;
}
