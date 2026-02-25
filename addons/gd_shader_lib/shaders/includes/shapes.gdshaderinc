// @name Shapes
// @category Fragment
// @type Spatial
// @description 2D Shapes

float gdslCircle(vec2 position, float radius, float feather){
	return smoothstep(radius, radius + feather, length(position - vec2(0.5)));
}
vec4 gdslSquare(vec2 uv, float width){
	uv = uv * 2.0 - 1.0;
	vec2 abs_uv = abs(uv.xy);
	float square = step(width, max(abs_uv.x, abs_uv.y));
	return vec4(vec3(square), 1.0);
}
vec4 gdslSquareStroke(vec2 uv, float width, float stroke_width){
	uv = uv * 2.0 - 1.0;
	vec2 abs_uv = abs(uv.xy);
	float dist = max(abs_uv.x, abs_uv.y);
	vec3 stroke = 1.0 - vec3( step(width, dist) - step(width + stroke_width, dist) );
	return vec4(vec3(stroke), 1.0);
}
vec4 gdslSquareRounded(vec2 uv, float width, float radius){
	uv = uv * 2.0 - 1.0;
	radius *= width; // make radius go from 0-1 instead of 0-width
	vec2 abs_uv = abs(uv.xy) - radius;
	vec2 dist = vec2(max(abs_uv.xy, 0.0));
	float square = step(width - radius, length(dist));
	return vec4(vec3(square), 1.0);
}
vec4 gdslPolygon(vec2 uv, float width, int sides){
	uv = uv * 2.0 - 1.0;
	float angle = atan(uv.x, uv.y);
	float radius = (PI * 2.0) / float(sides);
	float dist = cos(floor(0.5 + angle / radius) * radius - angle) * length(uv);
	float poly = step(width, dist);
	return vec4(vec3(poly), 1.0);
}
//float swirl = gdslSwirl(UV, 50.0, 6);
//COLOR += vec4(vec3(swirl), 1.0);
float gdslSwirl(vec2 uv, float size, int arms){
	float angle = atan(-uv.y + 0.5, uv.x - 0.5) ;
	float len = length(uv - vec2(0.5, 0.5));
	return sin(len * size + angle * float(arms));
}