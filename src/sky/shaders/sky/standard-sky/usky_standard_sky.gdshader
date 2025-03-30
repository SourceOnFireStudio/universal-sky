shader_type sky;
render_mode use_quarter_res_pass;

#define HIGH_QUALITY_SUN_DISK
//#define TONEMAP_ACES
#define ENABLE_TONEMAP

#include "res://addons/universal-sky/src/sky/shaders/library/usky_coords.gdshaderinc"
#include "usky_standard_atmosphere.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/library/usky_random.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/sky/common/usky_sun.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/sky/common/usky_moon.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/sky/common/usky_deep_space.gdshaderinc"

uniform float debanding_level;

vec3 colorCorrection(vec3 col, vec2 fragcoord){
	#ifdef ENABLE_TONEMAP
	col.rgb = tonemap(col.rgb, exposure, tonemap_level);
	#endif

	col.rgb += mix(vec3(0.0), interleavedGradientNoise(fragcoord), debanding_level);
	return (col.rgb);
}

void sky(){
	vec4 finalColor = vec4(0.0);
	vec3 worldPos = EYEDIR.xyz;

	vec3 horizonBlend = mix(vec3(0.0), vec3(1.0), smoothstep(-0.1, 1.0, dot(vec3(0.0, 1.0, 0.0),
		worldPos + vec3(0.0, horizon_offset, 0.0)) * 10.0)
	);

	// Atmosphere
	vec3 scatter = atmosphericScattering(worldPos, horizonBlend);

	// Near space
	vec3 nearSpace = vec3(0.0);
	vec3 sun = sunDisk(worldPos, sun_direction, sun_size) * sun_color.rgb * sun_intensity;
	sun *= scatter;
	vec4 moon = computeMoon(worldPos);
	nearSpace += (sun.rgb * moon.a) + moon.rgb;

	// Deep space
	vec3 deepSpace = vec3(0.0);
	vec3 deepSpaceCoords = getDeepSpaceCoords(worldPos);
	deepSpace += getBackground(equirectUV(deepSpaceCoords));
	deepSpace += getStarsField(equirectUV(deepSpaceCoords));
	deepSpace *= moon.a;
	deepSpace.rgb *= saturate(1.0-(sun_direction.y+0.85));

	// Apply deep and near space.
	finalColor.rgb += (deepSpace + nearSpace) * horizonBlend;
	finalColor.rgb += scatter;

	// Apply color correction.
	finalColor.rgb = colorCorrection(finalColor.rgb, FRAGCOORD.xy);

	if(AT_QUARTER_RES_PASS && AT_CUBEMAP_PASS){
		COLOR = finalColor.rgb;
		ALPHA = 1.0;
	}
	else if(AT_CUBEMAP_PASS){
		COLOR = QUARTER_RES_COLOR.rgb;
	}
	else{
		COLOR = finalColor.rgb;
	}
}