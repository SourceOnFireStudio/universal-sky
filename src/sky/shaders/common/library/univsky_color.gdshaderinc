#ifndef UNIVSKY_COLOR
#define UNIVSKY_COLOR

#define saturate(x) clamp(x, 0.0, 1.0)

vec3 contrastLevel(vec3 x, float level){
	return mix(x, x * x * x, level);
}

float remap(float value, float fromMin, float fromMax, float toMin, float toMax){
	return toMin + (value - fromMin) * (toMax - toMin) / (fromMax - fromMin);
}

#ifdef TONEMAP_ACES
vec3 tonemap(vec3 color, float exposure, float level){
	color.rgb *= exposure;
	const vec3  a = vec3(2.51);
	const float b = 0.03;
	const float c = 2.43;
	const float d = 0.59;
	const float e = 0.14;
	vec3 ret = (color.rgb * (a * color.rgb + b)) / (color.rgb * (c * color.rgb + d) + e);
	return mix(color.rgb, ret, level);
}
#else
vec3 tonemap(vec3 col, float exposure, float level){
	return mix(col.rgb * exposure,(1.0 - exp2(-col.rgb * exposure * 2.0)), level);
}
#endif

#endif