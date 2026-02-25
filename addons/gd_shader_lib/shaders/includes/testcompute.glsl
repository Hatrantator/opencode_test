// @name test
// @category 
// @type Compute
// @description 
#[compute]
#version 450

layout(set = 0, binding = 0, rgba32f) readonly uniform image2D computeTestImputTexture;
layout(set = 0, binding = 1, rgba32f) writeonly restrict uniform image2D computeTestOutputTexture;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);
	
	vec4 color = imageLoad(computeTestImputTexture, id);
	vec3 grayscale = vec3((color.r + color.g + color.b) / 3.0);
	
	imageStore(computeTestOutputTexture, id, vec4(grayscale, 1.0));
}
