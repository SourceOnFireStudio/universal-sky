#ifndef UNIVSKY_SUN
#define UNIVSKY_SUN
// https://www.shadertoy.com/view/slSXRW
float sunWithBloom(vec3 rayDir, vec3 sunDir, float size) {
    float sunSolidAngle = size * 0.017453293;
    float minSunCosTheta = cos(sunSolidAngle);

    float cosTheta = dot(rayDir, sunDir);
    if (cosTheta >= minSunCosTheta)
		return 1.0;

    float offset = minSunCosTheta - cosTheta;
    float gaussianBloom = exp(-offset*50000.0)*0.5;
    float invBloom = 1.0/(0.02 + offset*300.0)*0.01;
    return gaussianBloom+invBloom;
}

float sunDisk(vec3 pos, vec3 dir, lowp float size){
	mediump float ret = 0.0;
#ifdef HIGH_QUALITY_SUN_DISK
	//ret = (pow(2.0 - (2.0 * dot(dir, pos)), -1.5) * size*0.0001);
	ret = sunWithBloom(pos, dir, size);
#else
	ret = 1.0 - step(size * 0.017453293, length(pos - dir));
#endif
	///ret = min(50.0, ret); // Prevent reflection artifacts.
	return ret;
}
#endif