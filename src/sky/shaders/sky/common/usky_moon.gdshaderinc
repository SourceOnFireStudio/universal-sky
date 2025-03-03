#ifndef USKY_MOON
#define USKY_MOON
#include "res://addons/universal-sky/src/sky/shaders/library/usky_color.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/library/usky_coords.gdshaderinc"
#include "usky_variables.gdshaderinc"


struct SphereRay{
	vec3 origin;
	vec3 direction;
	float radius;
};

float moonSphere(SphereRay ray, inout float mask){
	ray.origin = -ray.origin;
	//float a = dot(ray.direction, ray.direction);
	float b = dot(ray.direction, ray.origin);
	float c = dot(ray.origin, ray.origin) - ray.radius * ray.radius;
	float d = b * b - c;
	if(d < 0.0){
		return -1.0;
	}
	d = sqrt(d);
	float ret = -b - d;
	mask = ret > -1.0 ? 1.0 : 0.0;

	return ret;
}

vec4 computeMoon(vec3 pos){
	float moonMu = dot(moon_direction, pos);

	SphereRay ray;
	ray.origin = pos;
	ray.direction = moon_direction;
	ray.radius = moon_size * 0.017453293;

	float mask = 0.0;
	float isphere = moonSphere(ray, mask);

	float ndotL = 0.0;
	vec3 normal = normalize(moon_direction - pos * isphere);
	ndotL += saturate(dot(normal, -sun_direction));

	vec3 texCoords = (moon_matrix * normal).xyz;
	texCoords.xy = equirectUV(texCoords);
	texCoords.x += -0.3;

	vec4 color = texture(moon_texture, texCoords.xy);
	color.rgb *= moon_color.rgb * moon_intensity;
	color.rgb = contrastLevel(color.rgb, moon_color.a);

	float fix = saturate(dot(pos.xyz, moon_direction.xyz));
	vec3 result = (mask * color.rgb) * ndotL * fix;

	return vec4(result.rgb, saturate(1.0 - mask));
}
#endif