#ifndef UNIVSKY_DYNAMIC_CLOUDS
#define UNIVSKY_DYNAMIC_CLOUDS

#include "res://addons/universal-sky/src/sky/shaders/common/library/univsky_color.gdshaderinc"

uniform sampler2D dynamic_clouds_texture: source_color;
uniform float dynamic_clouds_coverage = 0.5;
uniform float dynamic_clouds_absorption = 15.0;
uniform float dynamic_clouds_density = 30.0;

uniform vec2 dynamic_clouds_direction = vec2(0.005);
uniform float dynamic_clouds_size = 1.0;
uniform vec2 dynamic_clouds_uv = vec2(0.1, 0.1);

vec2 getDynamicCloudsUV(vec3 pos){
	pos.xz = pos.xz / pos.y;
	return pos.xz * dynamic_clouds_size;
}

vec4 dynamicClouds(vec2 uv, float time){
	vec4 res = vec4(0.0);
	
	vec2 wind = time * dynamic_clouds_direction;
	vec2 wind2 = time * 2.0 * dynamic_clouds_direction;
	float noiseA = textureLod(dynamic_clouds_texture, uv * dynamic_clouds_uv + wind, 0.0).r;
	float noiseB = textureLod(dynamic_clouds_texture, uv * dynamic_clouds_uv + wind2, 0.0).r;
	
	float noise = (noiseA + noiseB) * 0.5;
	float coverage = 1.0 - dynamic_clouds_coverage;
	
	float density = noise - coverage;
	float sh = saturate(exp(-dynamic_clouds_absorption * density));
	float a = saturate(density * dynamic_clouds_density);
	
	res.rgb = vec3(sh);
	res.a = a;
	
	return res;
}

#endif