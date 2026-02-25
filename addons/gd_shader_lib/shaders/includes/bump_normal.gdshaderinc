// @name bump_normal
// @category Fragment
// @type Spatial
// @description

uniform sampler2D bumpHeightMap;
uniform float bumpStrength : hint_range(0.0, 2.0) = 1.0;
uniform float bumpSmoothness: hint_range(0.0, 5.0) = 1.0;
uniform vec2 bumpTexelSize = vec2(0.001, 0.001); // 1 / texture size

vec3 bumpNormal(vec2 uv) {
    // Sample center height
    float h = texture(bumpHeightMap, uv).r;

    // Smoothed sampling offsets
    vec2 dx = vec2(bumpTexelSize.x * bumpSmoothness, 0.0);
    vec2 dy = vec2(0.0, bumpTexelSize.y * bumpSmoothness);

    float hL = texture(bumpHeightMap, uv - dx).r;
    float hR = texture(bumpHeightMap, uv + dx).r;
    float hD = texture(bumpHeightMap, uv - dy).r;
    float hU = texture(bumpHeightMap, uv + dy).r;

    // Height derivatives
    float dX = (hR - hL) * bumpStrength;
    float dY = (hU - hD) * bumpStrength;

    // Construct tangent-space normal
    vec3 normal_ts = normalize(vec3(-dX, -dY, 1.0));

    return normal_ts;

    // Optional visualization
    //ALBEDO = normal_ts * 0.5 + 0.5;
}
