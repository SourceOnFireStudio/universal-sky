shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, skip_vertex_transform;

#include "res://addons/universal-sky/src/sky/shaders/library/usky_coords.gdshaderinc"

uniform vec4 background_color: source_color;

void vertex() {
	vec4 vertex;
	computeDomePosition(POSITION, vertex, VERTEX, MODELVIEW_MATRIX, PROJECTION_MATRIX);
}

void fragment() {
	ALBEDO  = background_color.rgb;
}