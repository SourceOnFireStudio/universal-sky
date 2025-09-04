shader_type sky;
render_mode use_quarter_res_pass, use_half_res_pass;

#define HIGH_QUALITY_SUN_DISK
//#define TONEMAP_ACES
#define ENABLE_TONEMAP

#include "res://addons/universal-sky/src/sky/shaders/common/library/univsky_coords.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/atmospheric-scattering/univsky_atmospheric_scattering.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/common/library/univsky_random.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/outer-space/univsky_sun.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/outer-space/univsky_moon.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/outer-space/univsky_deep_space.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/dynamic-clouds/univsky_dynamic_clouds.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/clouds_panorama/univsky_clouds_panorama.gdshaderinc"

uniform float debanding_level;
uniform bool enable_dynamic_clouds;
uniform bool enable_clouds_panorama;

vec3 colorCorrection(vec3 col, vec2 fragcoord){
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	col.rgb = sqrt(col.rgb);
	#endif
	#ifdef ENABLE_TONEMAP
	col.rgb = tonemap(col.rgb, exposure, tonemap_level);
	#endif
	col.rgb += mix(vec3(0.0), interleavedGradientNoise(fragcoord), debanding_level);
	return (col.rgb);
}

vec4 getSky(vec3 scatter, vec3 pos, vec3 horizonBlend, float time){
	vec4 finalColor = vec4(0.0);
	
	// Near space
	vec3 nearSpace = vec3(0.0);
	vec3 sun = sunDisk(pos, sun_direction, sun_size) * sun_color.rgb * sun_intensity;
	sun *= scatter;
	vec4 moon = computeMoon(pos);
	nearSpace += (sun.rgb * moon.a) + moon.rgb;
	
	// Deep space
	vec3 deepSpace = vec3(0.0);
	vec3 deepSpaceCoords = getDeepSpaceCoords(pos);
	vec2 deepSpaceUV = equirectUV(deepSpaceCoords) + vec2(0.5, 0.0);
	deepSpace += getBackground(deepSpaceUV);
	deepSpace += getStarsField(deepSpaceUV, time);
	deepSpace *= moon.a;
	deepSpace.rgb *= saturate(1.0-(sun_direction.y+0.85));
	
	// Sun eclipse
	scatter *= sun_eclipse_intensity;
	
	// Apply deep and near space.
	finalColor.rgb += (deepSpace + nearSpace) * horizonBlend;
	
	// Apply atmospheric scattering.
	finalColor.rgb += scatter; 
	
	// Clouds
	vec3 cloudsColor = vec3(0.0);
	vec3 cloudsFog = vec3(0.0);
	float cloudsBlend = 0.0;
	if(enable_dynamic_clouds || enable_clouds_panorama){
		cloudsColor = cloudsColorScattering(pos+vec3(0.0, -1.0, 0.0), horizonBlend, vec3(0.0));
		cloudsBlend = saturate(pos.y * 7.0);
		cloudsBlend *= cloudsBlend * cloudsBlend;
		cloudsFog = scatter;
	}
	
	// 2D Dynamic Clouds
	float dynamicloudsAlpha = 0.0;
	if(enable_dynamic_clouds)
	{
		vec2 cloudsUV = getDynamicCloudsUV(pos);
		vec4 clouds = dynamicClouds(cloudsUV, cloudsColor, time);
		finalColor.rgb = mix(finalColor.rgb, clouds.rgb + cloudsFog, clouds.a * cloudsBlend);
		dynamicloudsAlpha = clouds.a;
	}
	
	// Clouds Panorama
	if(enable_clouds_panorama)
	{
		vec4 pano = cloudsPanoramaRB(pos, cloudsColor, time);
		finalColor.rgb = mix(finalColor.rgb, pano.rgb + cloudsFog, pano.a * cloudsBlend * (1.0-dynamicloudsAlpha));
	}
	return finalColor;
}

void sky(){
	vec3 worldPos = EYEDIR.xyz;
	vec3 horizonBlend = mix(vec3(0.0), vec3(1.0), smoothstep(-0.1, 1.0, dot(vec3(0.0, 1.0, 0.0),
		worldPos + vec3(0.0, horizon_offset, 0.0)) * 10.0)
	);
	
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY // Compability pass
	vec3 atm = atmosphericScattering(worldPos, horizonBlend);
	COLOR = getSky(atm, worldPos, horizonBlend, TIME).rgb;
	COLOR = colorCorrection(COLOR, FRAGCOORD.xy);
	#else
	if(AT_QUARTER_RES_PASS && AT_CUBEMAP_PASS){ // Quarter resolution reflection pass
		vec3 atm = atmosphericScattering(worldPos, horizonBlend);
		COLOR = getSky(atm, worldPos, horizonBlend, TIME).rgb;
		COLOR.rgb = colorCorrection(COLOR.rgb, FRAGCOORD.xy);
	}
	else if(AT_HALF_RES_PASS && !AT_CUBEMAP_PASS){ // Atmosphere pass 
		vec3 atms = atmosphericScattering(worldPos, horizonBlend);
		COLOR = atms.rgb;
	}
	else if(AT_CUBEMAP_PASS){ // Full resolution reflection pass
		COLOR = QUARTER_RES_COLOR.rgb;
	}
	else{ // Main Pass
		COLOR = getSky(HALF_RES_COLOR.rgb, worldPos, horizonBlend, TIME).rgb;
		COLOR = colorCorrection(COLOR, FRAGCOORD.xy);
	}
	#endif
}
