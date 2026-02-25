// placement_compute.glsl
#[compute]
#version 450
layout(local_size_x = 8, local_size_y = 8) in;

layout(set=0, binding=0, r16f)
uniform readonly image2D heightmap;

layout(set=0, binding=1, rgba8)
uniform readonly image2D vegetation_map;

layout(set=0, binding=2, rgba16f)
uniform writeonly image2D placement_out;

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

	float h = imageLoad(heightmap, uv).r;
	vec4 veg = imageLoad(vegetation_map, uv);

	float enabled = 0.0;
	if (veg.b > 0.5 && h > 0.1) { // grass only
		enabled = 1.0;
	}

	float scale = mix(0.8, 1.2, fract(sin(dot(vec2(uv), vec2(12.9898,78.233))) * 43758.5));
	float rotation = fract(h * 10.0);

	imageStore(placement_out, uv, vec4(enabled, scale, rotation, 1.0));
}
