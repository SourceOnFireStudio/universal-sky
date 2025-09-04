#ifndef UNIVSKY_CLOUDS_PANORAMA
#define UNIVSKY_CLOUDS_PANORAMA

#include "res://addons/universal-sky/src/sky/shaders/common/library/univsky_coords.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/common/library/univsky_color.gdshaderinc"
uniform sampler2D clouds_panorama: source_color, filter_linear, hint_default_black;
uniform float clouds_panorama_speed = 0.01;
uniform float clouds_panorama_intensity = 1.0;

vec4 cloudsPanoramaRB(vec3 pos, vec3 color, float time){
	vec3 cloudsPos = vec3(pos.x , pos.y, pos.z);
	vec2 clouds = textureLod(clouds_panorama, equirectUV(cloudsPos) + vec2((time * clouds_panorama_speed), 0.0), 0.0).rb;
	return vec4(clouds.x * color *  clouds_panorama_intensity, saturate(clouds.y));
}

#endif