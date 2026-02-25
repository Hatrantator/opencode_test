// @name Quadbased Offset Modifier
// @category Vertex
// @type Spatial
// @description Vertex Offset for Quad based Meshes eg. QuadSphere, QuadCube for fluffy foliage

uniform float gdslQuadOffsetScale : hint_range(0.0001, 1.0, 0.001) = 0.01;

vec2 apply_quadoffset_modifier(vec2 uv, vec3 normal, vec3 viewDir) {
    float offsetAmount = dot(normalize(normal), normalize(viewDir)) * gdslQuadOffsetScale;
    vec2 offsetUV = uv + vec2(offsetAmount, offsetAmount);
    return offsetUV;
 }
// Vertex Offset Function
// Offset needs to be added to VERTEX in the vertex function
vec3 offset_vertex(vec2 uv, mat4 modelView) {
    vec2 uvOffset = vec2(uv.x * 2.0 - 1.0, -(uv.y * 2.0 - 1.0));
	uvOffset /= 2.0;
	vec4 off = inverse(modelView) * vec4(uvOffset,1.0,0.0);
	off = vec4(normalize(off.xyz),0.0) * gdslQuadOffsetScale;
    return off.xyz;
 }