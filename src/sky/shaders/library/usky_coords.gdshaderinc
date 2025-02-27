#ifndef USKY_COORDS
#define USKY_COORDS
#include "usky_const.gdshaderinc"

vec2 equirectUV(vec3 norm){
	vec2 ret;
	ret.x = (atan(norm.x, norm.z) + kPI) * kINV_TAU;
	ret.y = acos(norm.y) * kINV_PI;
	return ret;
}

void compute_dome_position(out vec4 position, out vec4 customVertex,
	inout vec3 vertex, in mat4 modelview, in mat4 projection){
	position = vec4(0.0);
	customVertex = vec4(vertex, 0.0);
	customVertex *= 1000000.0;
	vertex = (modelview * customVertex).xyz;
	position = (projection * modelview * customVertex);
	position.z = 0.0;
}

#endif