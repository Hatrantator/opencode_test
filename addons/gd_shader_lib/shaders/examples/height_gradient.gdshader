shader_type spatial;
render_mode unshaded;

// 1D Gradient Texture
uniform sampler2D height_gradient : source_color;

// Height range in world space
uniform float min_height = 0.0;
uniform float max_height = 10.0;

varying float world_height;

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_height = world_pos.y;
}

void fragment() {
    // Normalize height to 0–1
    float t = clamp(
        (world_height - min_height) / (max_height - min_height),
        0.0,
        1.0
    );

    // Sample gradient texture (vertical coord fixed at 0.5)
    vec3 gradient_color = texture(height_gradient, vec2(t, 0.5)).rgb;

    ALBEDO = gradient_color;
}
