#ifndef USKY_VARIABLES
#define USKY_VARIABLES

// General Settings
uniform float exposure = 1.0;
uniform float tonemap_level = 0.0;
uniform float horizon_offset = 0.0;

// Sun.
uniform vec3 sun_direction;
uniform vec4 sun_color: source_color;
uniform float sun_intensity;
uniform float sun_size;
uniform float sun_eclipse_intensity;

// Moon.
uniform vec3 moon_direction;
uniform vec4 moon_color: source_color;
uniform float moon_intensity;
uniform float moon_size;
uniform sampler2D moon_texture;
uniform float moon_texture_yaw_offset;
uniform mat3 moon_matrix;

// Atmosphere
// Sun Mie
uniform float atm_sun_mie_anisotropy;
uniform vec4 atm_sun_mie_color: source_color;
uniform float atm_sun_mie_intensity;

// Moon Mie
uniform float atm_moon_mie_anisotropy;
uniform vec4 atm_moon_mie_color: source_color;
uniform float atm_moon_mie_intensity;

#endif