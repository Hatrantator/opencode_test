// Global uniforms for cloud shadows
global uniform sampler2D cloud_texture : hint_default_black, filter_linear_mipmap;
uniform vec2 cloud_scale = vec2(0.1, 0.1); // Scale of the cloud texture
uniform vec2 cloud_scroll_speed = vec2(0.1, 0.1); // Speed of cloud scrolling
uniform float cloud_intensity : hint_range(0.0, 1.0) = 1.0; // Intensity of the cloud shadows

// Function to calculate cloud shadow attenuation
float get_cloud_attenuation(vec3 world_pos) {
    // Calculate scrolling UV coordinates
    vec2 uv = world_pos.xz * cloud_scale + TIME * cloud_scroll_speed;

    // Repeat the texture (wrap UVs)
    uv = fract(uv);

    // Sample the cloud texture
    float cloud_value = texture(cloud_texture, uv).r;

    // Invert the cloud value to represent shadows (dark areas)
    return mix(1.0, cloud_value, cloud_intensity);
}