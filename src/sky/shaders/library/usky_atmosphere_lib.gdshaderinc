#ifndef USKY_ATMOSPHERE_LIB
#define USKY_ATMOSPHERE_LIB
#include "usky_const.gdshaderinc"

float rayleighPhase(float mu){
	return k3PI16 * (1.0 + mu * mu);
}

float miePhase(float mu, float g){
	float g2 = g*g;
	return kPI4 * ((1.0 - g2) / (2.0 + g2)) *
		(pow((1.0 + g2) - (2.0 * g) * mu, -1.5));
}

float betaMie(float mie, float turbidity){
	const float k = 434e-6;
	return 1.0 * mie * turbidity * k;
}

// See: https://www.shadertoy.com/view/msXXDS
float miePhaseInv(float mu, float g){
	float g2 = g*g;
	float d = 1.0 + g2 + 2.0 * g * -mu;
	return 5.0 * (1.0 - g2) /  (d * sqrt(d));
}

#endif