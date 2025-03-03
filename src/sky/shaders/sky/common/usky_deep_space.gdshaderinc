#ifndef USKY_DEEP_SPACE
#define USKY_DEEP_SPACE
#include "res://addons/universal-sky/src/sky/shaders/library/usky_color.gdshaderinc"
#include "usky_variables.gdshaderinc"

// Background.
uniform sampler2D background_texture: source_color;
uniform vec4 background_color: source_color;

// Stars Field.
uniform sampler2D stars_field_texture: source_color;
uniform sampler2D noise_tex: source_color;
uniform vec4 stars_field_color: source_color;
uniform float stars_field_intensity;
uniform float stars_scintillation;
uniform float stars_scintillation_speed;
uniform mat3 deep_space_matrix;

vec3 getDeepSpaceCoords(vec3 pos){
	return deep_space_matrix * pos.xyz;
}

vec3 getBackground(vec2 uv){
	return contrastLevel(
		textureLod(background_texture, uv, 0.0).rgb * background_color.rgb,
			background_color.a
	);
}

vec3 getStarsField(vec2 uv){
	float field = textureLod(stars_field_texture, uv, 0.0).r;
	field = mix(field, field
		* saturate(sin(field * ((TIME*20.0) * stars_scintillation_speed))),
		stars_scintillation
	);
	return saturate(field) * stars_field_intensity * stars_field_color.rgb;
}
#endif