shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, skip_vertex_transform;

uniform vec4 background_color: source_color;

void compute_dome_position(out vec4 position, out vec4 customVertex, inout vec3 vertex, in mat4 modelview, in mat4 projection){
	position = vec4(0.0);
	customVertex = vec4(vertex, 0.0);
	customVertex *= 1000000.0;
	vertex = (modelview * customVertex).xyz;
	position = (projection * modelview * customVertex);
	position.z = 0.0;
}

void vertex() {
	vec4 vertex;
	compute_dome_position(POSITION, vertex, VERTEX, MODELVIEW_MATRIX, PROJECTION_MATRIX);
}

void fragment() {
	ALBEDO  = background_color.rgb;
}


