// @name Basic
// @category Other
// @type Spatial
// @description Basic Operations needed wherever

//pseudo randomized values
vec3 hash33(vec3 p) {
	p = fract(p * 0.4567);
	p += dot(p, p.yzx + 1.3456);
	p.x *= p.x;
	p.y *= p.y;
	p.z *= p.z;
	return fract(p);
}