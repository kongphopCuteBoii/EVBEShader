#include "fragmentVersionCentroid.h"
#include "uniformShaderConstants.h"
#include "util.h"

#define skyShader
#include "libs/! config.glsl"
#include "libs/EVBE_lib.glsl"
#include "libs/EVBE_color.glsl"
#include "libs/EVBE_noise.glsl"
varying hp vec3 wPos;

#include "libs/EVBE_function.glsl"

void main() {
    hp vec3 wp = wPos, np = normalize(vec3(wp.x, -wp.y+0.128, -wp.z));
    vec3 albedo = getAestheticSky(np, 1);
    gl_FragColor = vec4(colorMask(albedo), 1);
}






























// Name : EVBE_v0.8r-cubemap.fsh
// Notice : Some of code has been taken from the internet and Mojang.
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved to their respective owners.