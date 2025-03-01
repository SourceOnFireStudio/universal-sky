shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, skip_vertex_transform;

#include "res://addons/universal-sky/src/sky/shaders/library/usky_coords.gdshaderinc"
#include "usky_standard_atmosphere.gdshaderinc"

varying vec3 v_world_pos;

void vertex(){
	vec4 customVertex;
	computeDomePosition(POSITION, customVertex, VERTEX, MODELVIEW_MATRIX, PROJECTION_MATRIX);
	v_world_pos = (MODEL_MATRIX * customVertex).xyz;
}

void fragment(){
	vec4 col = vec4(0.0);
	vec3 worldPos = normalize(v_world_pos);
	vec3 horizonBlend = mix(
		vec3(0.0), vec3(1.0),
		smoothstep(-0.1, 1.0, dot(vec3(0.0, 1.0, 0.0),
			worldPos + vec3(0.0, horizon_level, 0.0)) * 10.0)
	);
	vec3 scatter = atmosphericScattering(worldPos, horizonBlend);
	col.rgb += scatter;

	ALBEDO = col.rgb;
}