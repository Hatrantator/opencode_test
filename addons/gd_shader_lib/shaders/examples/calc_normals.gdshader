shader_type spatial;
render_mode vertex_lighting;

uniform sampler2D heightmap;
uniform vec2 heightmap_size; // z.B. vec2(512.0, 512.0)
uniform float height_scale = 1.0;

vec3 compute_normal(vec2 uv) {
    vec2 texel = 1.0 / heightmap_size;

    float hL = texture(heightmap, uv + vec2(-texel.x, 0.0)).r;
    float hR = texture(heightmap, uv + vec2( texel.x, 0.0)).r;
    float hD = texture(heightmap, uv + vec2(0.0, -texel.y)).r;
    float hU = texture(heightmap, uv + vec2(0.0,  texel.y)).r;

    vec3 tangent   = normalize(vec3(2.0 * texel.x, hR - hL, 0.0));
    vec3 bitangent = normalize(vec3(0.0, hU - hD, 2.0 * texel.y));

    return normalize(cross(bitangent, tangent));
}

void vertex() {
    float height = texture(heightmap, UV).r * height_scale;

    // Höhe anwenden (Y-Achse = up)
    VERTEX.y += height;

    // Normale neu berechnen
    NORMAL = compute_normal(UV);
}
