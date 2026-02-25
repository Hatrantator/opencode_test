shader_type spatial;
render_mode world_vertex_coords, ensure_correct_normals;

#include "res://addons/gd_shader_lib/shaders/includes/hue_mask.gdshaderinc"

uniform sampler2D tex_x;
uniform sampler2D tex_y;
uniform sampler2D tex_z;

uniform vec3 flat_color  : source_color = vec3(0.1, 0.6, 0.1);
uniform vec3 steep_color : source_color = vec3(0.45, 0.3, 0.15);

uniform float bottom_threshold = 3.5;
uniform float slope_start = 0.7;
uniform float slope_end   = 0.9;
uniform float texture_scale = 0.1;

varying vec3 world_pos;
varying vec3 world_nrm;

void vertex() {
    world_pos = VERTEX;

    // Transform normal to world space
    world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	hue = hueValue(world_pos, hueMaskTexture);
}

vec3 triplanar(vec3 pos, vec3 nrm) {
    vec3 n = abs(nrm);
    n = max(n, 0.0001);
    n /= (n.x + n.y + n.z);

    vec3 x = texture(tex_x, pos.yz * texture_scale).rgb;
    vec3 y = texture(tex_y, pos.xz * texture_scale).rgb;
    vec3 z = texture(tex_z, pos.xy * texture_scale).rgb;

    return x * n.x + y * n.y + z * n.z;
}

void fragment() {
    vec3 nrm = normalize(world_nrm);

    // Triplanar texture
    vec3 tex_color = triplanar(world_pos, nrm);

    // Slope blend using WORLD UP
    float slope = dot(nrm, vec3(0.0, 1.0, 0.0));
    float t = smoothstep(slope_start, slope_end, slope);

    vec3 slope_color = mix(steep_color, flat_color*hue, t);

	if (world_pos.y < bottom_threshold) {
		 ALBEDO = tex_color * steep_color;
	} else {
    	ALBEDO = tex_color * slope_color;
	}
	//ALBEDO = tex_color * slope_color;
}
