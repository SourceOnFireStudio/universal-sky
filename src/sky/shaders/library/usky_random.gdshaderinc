#ifndef USKY_RANDOM
#define USKY_RANDOM

// Simple random from https://thebookofshaders.com/10/
float simpleRandom(vec2 st){
	return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// https://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
vec3 interleavedGradientNoise(vec2 pos) {
	const vec3 magic = vec3(0.06711056f, 0.00583715f, 52.9829189f);
	float res = fract(magic.z * fract(dot(pos, magic.xy))) * 2.0 - 1.0;
	return vec3(res, -res, res) * 0.00392156862745; // / 255.0;
}

#endif