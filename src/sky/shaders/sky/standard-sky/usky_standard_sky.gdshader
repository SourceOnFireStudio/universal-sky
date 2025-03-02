shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, skip_vertex_transform;

#include "res://addons/universal-sky/src/sky/shaders/library/usky_coords.gdshaderinc"
#include "usky_standard_atmosphere.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/library/usky_random.gdshaderinc"

varying vec3 v_world_pos;

void vertex(){
	vec4 customVertex;
	computeDomePosition(POSITION, customVertex, VERTEX, MODELVIEW_MATRIX, PROJECTION_MATRIX);
	v_world_pos = (MODEL_MATRIX * customVertex).xyz;
}

#define COLOR_CORRECTION(col) col.rgb = tonemap(col.rgb, tod_exposure, tod_tonemap_level);  \
	col.rgb += tod_apply_debanding ? interleavedGradientNoise(FRAGCOORD.xy): vec3(0.0)

vec3 colorCorrection(vec3 col, vec2 fragcoord){
	col.rgb = tonemap(col.rgb, exposure, tonemap_level);
	col.rgb += interleavedGradientNoise(fragcoord.xy);
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
	vec3 scatter = atmosphericScattering(worldPos, horizonBlend);
	col.rgb += scatter;

	ALBEDO = colorCorrection(col.rgb, FRAGCOORD.xy);
}