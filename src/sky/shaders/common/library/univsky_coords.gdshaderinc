#ifndef UNIVSKY_COORS
#define UNIVSKY_COORS
#include "univsky_const.gdshaderinc"

vec2 equirectUV(vec3 norm){
	vec2 ret;
	ret.x = (atan(norm.x, norm.z) + kPI) * kINV_TAU;
	ret.y = acos(norm.y) * kINV_PI;
	return ret;
}

#endif