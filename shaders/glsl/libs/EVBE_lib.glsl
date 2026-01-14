// [!] You should not make a change here if you have no idea to edit this properly.
#define lp lowp
#ifdef GL_FRAGMENT_PRECISION_HIGH
    #define hp highp
#else
    #define hp mediump
#endif

#define tm TIME
#define fc FOG_COLOR
#define fcn FOG_CONTROL
#define rd RENDER_DISTANCE
#define tdm TEXTURE_DIMENSIONS
uniform vec4 fc;
uniform vec2 fcn;
uniform float rd;
uniform hp float tm;

#define smoother(x) smoothstep(0.0, 1.0, x)
#define smoothest(x) (x*x*(3.0-2.0*x))
#define saturate(x) clamp(x, 0.0, 1.0)
#define max0(x) max(x, 0.0)
#define min1(x) min(x, 1.0)
#define mul(x, y) (y*x)
const float pi = 3.14, hPi = 1.57, invPi = 0.32;

#define low 0
#define med 1
#define ext 2

#include "r.glsl"
//const float normalValue = 0.0078125, pbrValue = 0.015625, detectionValue = 0.0234375;

mat2 rot(float anj) {
    float s = sin(anj), c = cos(anj);
    return mat2(s, c, -c, s);
}
float getTime(vec4 fog) {
    return fog.g > 0.213101 ? 1.0 : dot(vec4(fog.g*fog.g*fog.g, fog.g*fog.g, fog.g, 1.0), vec4(349.305545, -159.858192, 30.557216, -1.628452));
}
hp vec3 getSunAngle() {
    float sunHeight = mix(-0.2, 1.0, max0(getTime(fc)));
    hp vec3 sunAngle = normalize(vec3(cos(sunHeight), sin(sunHeight), 0.0));
    return vec3(sunAngle.x, mul(rot(-5.0), sunAngle.yz));
}
hp vec3 getMoonAngle() {
    float moonHeight = tm*0.002;
    hp vec3 moonAngle = normalize(vec3(sin(moonHeight), abs(cos(moonHeight))+0.3, 0.0));
    return vec3(moonAngle.x, mul(rot(-10.0), moonAngle.yz*vec2(1, -1)));
}
#define daylight smoothstep(0.0, 0.5, getSunAngle().y)
#define night smoothstep(0.0, -0.1, getSunAngle().y)
#define dusk saturate(1.0-max(daylight, night))
#define rain ((fcn.x == 0.0) ? 0.0 : smoothstep(0.7, 0.1, fcn.x))

hp vec3 getLightAngle() {
    return mix(getSunAngle(), getMoonAngle(), night);
}
#define sunAngle getSunAngle()
#define moonAngle getMoonAngle()
#define lightAngle getLightAngle()

/*
float getTH(lowp vec2 uv) {
    return luminance(getTextureCol(uv).rgb);
}
float getBTH(vec2 uv) {
    return getTH(uv-saturate(0.5/tdm.xy));
}
vec3 getAGNS(lowp vec2 uv) {
    vec2 d = 1.0/tdm.xy;
    float e = getBTH(uv);
    vec2 f = e-vec2(getBTH(uv+vec2(d.x, 0)),
                    getBTH(uv+vec2(0, d.y)));
    return normalize(vec3(saturate(f*0.0002/d), 1));
}
*/






















// Name : EVBE's library file v0.8r
// Notice : -
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved.