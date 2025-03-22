shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, skip_vertex_transform;
#define HIGH_QUALITY_SUN_DISK
//#define TONEMAP_ACES

#include "res://addons/universal-sky/src/sky/shaders/library/usky_coords.gdshaderinc"
#include "usky_standard_atmosphere.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/library/usky_random.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/sky/common/usky_sun.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/sky/common/usky_moon.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/sky/common/usky_deep_space.gdshaderinc"

varying vec3 v_world_pos;

void vertex(){
	vec4 customVertex;
	computeDomePosition(POSITION, customVertex, VERTEX, MODELVIEW_MATRIX, PROJECTION_MATRIX);
	v_world_pos = (MODEL_MATRIX * customVertex).xyz;
}

vec3 colorCorrection(vec3 col, vec2 fragcoord){
	#ifdef ENABLE_TONEMAP
	col.rgb = tonemap(col.rgb, exposure, tonemap_level);
	#endif
	#ifdef ENABLE_DEBANDING
	col.rgb += interleavedGradientNoise(fragcoord.xy);
	#endif
	return col.rgb;
}

void fragment(){
	vec4 col = vec4(0.0);
	vec3 worldPos = normalize(v_world_pos);
	vec3 horizonBlend = mix(
		vec3(0.0), vec3(1.0),
		smoothstep(-0.1, 1.0, dot(vec3(0.0, 1.0, 0.0),
			worldPos + vec3(0.0, horizon_offset, 0.0)) * 10.0)
	);

	// Atmosphere
	vec3 scatter = atmosphericScattering(worldPos, horizonBlend);

	// Near Space
	vec3 nearSpace = vec3(0.0);
	vec3 sun = sunDisk(worldPos, sun_direction, sun_size) * sun_color.rgb * sun_intensity;
	sun *= scatter;
	vec4 moon = computeMoon(worldPos);
	nearSpace += (sun.rgb * moon.a) + moon.rgb;

	vec3 deepSpace = vec3(0.0);
	vec3 deepSpaceCoords = getDeepSpaceCoords(worldPos);
	deepSpace += getBackground(equirectUV(deepSpaceCoords));
	deepSpace += getStarsField(equirectUV(deepSpaceCoords));
	deepSpace *= moon.a;
	deepSpace.rgb *= saturate(1.0-(sun_direction.y+0.85));

	col.rgb += (deepSpace + nearSpace) * horizonBlend;
	col.rgb += scatter;

	ALBEDO = colorCorrection(col.rgb, FRAGCOORD.xy);
}