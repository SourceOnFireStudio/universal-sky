#ifndef UNIVSKY_ATMOSPHERIC_SCATTERING
#define UNIVSKY_ATMOSPHERIC_SCATTERING

#include "res://addons/universal-sky/src/sky/shaders/common/library/univsky_const.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/common/library/univsky_atmosphere_common.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/common/library/univsky_color.gdshaderinc"
#include "res://addons/universal-sky/src/sky/shaders/common/univsky_variables.gdshaderinc"

// Based on classic atmospheric scattering ATI (Phreetham and Hoffman) paper.
// See: https://drivers.amd.com/developer/gdc/GDC02_HoffmanPreetham.pdf
// This atmosphere has some hacks.

// Rayleigh.
uniform float atm_day_intensity = 15.0;
uniform float atm_contrast = 0.1;
uniform float atm_thickness = 1.0;
uniform float atm_rayleigh_level = 1.0;
uniform vec4 atm_day_tint: source_color = vec4(1.0);
uniform vec4 atm_night_tint: source_color = vec4(0.255, 0.337, 0.447, 1.0);
uniform vec3 atm_beta_ray;

// Mie.
uniform vec3 atm_beta_mie;
uniform vec4 atm_ground_color: source_color = vec4(0.255, 0.337, 0.447, 1.0);

uniform float sun_uMuS;

const float kRayleighZenithLength = 8.4e3;
const float kMieZenithLength = 1.25e3;

// Simplified and with added ground color.
void opticalDepth(float y, out vec3 sr, out vec3 sm){
	vec3 zenith = max(0.03, y + 0.03) + (max(0.0, -y) * atm_ground_color.xyz);
	zenith = 1.0 / zenith;
	sr = vec3(zenith * kRayleighZenithLength * atm_rayleigh_level);
	sm = vec3(zenith * kMieZenithLength);
}

vec3 atmosphericScattering(vec3 pos, vec3 horizonBlend){
	vec3 sr, sm;
	opticalDepth(pos.y+horizon_offset, sr, sm);

	vec3 betaMie = atm_beta_mie;
	vec3 betaRay = atm_beta_ray * atm_thickness;

	float sunMus = sun_uMuS - 1.0;

	// TODO: Improve
	float sunset = mix(sunMus, (sunMus * 0.05), atm_thickness - 1.0);
	sunset = saturate(sunset);

	vec3 extinction = saturate(exp(-betaRay * sr + betaMie * sm));
	vec3 extincH = (1.0 -(extinction * 0.75)) * sr * 0.00002;
	vec3 finalExtc = mix((1.0-extinction), extinction * extincH, 1.0-sunset);

	float sunMu = dot(sun_direction, pos);
	float rayleighPhase = rayleighPhase(sunMu);

	vec3 BRT = betaRay * rayleighPhase;
	vec3 BMT = betaMie *  miePhaseInv(sunMu, atm_sun_mie_anisotropy);

	BMT *= atm_sun_mie_intensity * atm_sun_mie_color.rgb;
	vec3 BRMT = (BRT+BMT) / (betaRay + betaMie);
	BRMT = mix(BRMT, BRMT * (1.0 - extinction), atm_contrast);

	vec3 Lin = atm_day_intensity * (BRMT * finalExtc) * saturate(sun_uMuS -0.2);
	Lin *= atm_day_tint.rgb;

	// Night
	float moonMu = dot(moon_direction, pos);
	vec3 nLin = (1.0 - extinction) ;
	nLin += miePhaseInv(moonMu, atm_moon_mie_anisotropy)
		* atm_moon_mie_color.rgb * (atm_moon_mie_intensity * 0.005) * horizonBlend;

	nLin *= atm_night_tint.rgb;

	return Lin + nLin;
}

#endif