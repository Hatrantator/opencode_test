// @name Normal Sway
// @category Vertex
// @type Spatial
// @description Sways Vertices based on NormalMap values


// Optional source_color
uniform sampler2D swayNormalMap;
uniform float swayStrength : hint_range(0.0, 5.0, 0.1) = 0.3;
uniform float swaySpeed = 0.0;
uniform float swayWorldUVScale = 0.25;
uniform float swayHeight = 1.0;

//vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
vec3 swayOffset(vec3 world_pos, vec3 vertex) {
	vec2 sway_uv = world_pos.xz * swayWorldUVScale;
	vec3 normal_sample = texture(swayNormalMap, sway_uv).rgb;
	vec3 sway_normal = normal_sample * 2.0 - 1.0;
    float wave = sin(TIME * swaySpeed + world_pos.x);

    // Höhenabhängige Abschwächung (z. B. Stamm fest, Spitze beweglich)
    float height_factor = clamp(vertex.y * swayHeight, 0.0, 1.0);

    // Finale Verschiebung
    vec3 offset = sway_normal * wave * swayStrength * height_factor;
	return offset;
}
