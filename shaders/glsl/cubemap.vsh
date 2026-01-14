#include "vertexVersionCentroidUV.h"
#include "libs/EVBE_lib.glsl"
uniform MAT4 WORLDVIEWPROJ;
attribute POS4 POSITION;
attribute vec2 TEXCOORD_0;
varying hp vec3 wPos;
varying vec2 texUv;

void main() {
    gl_Position = WORLDVIEWPROJ*POSITION;
    wPos = POSITION.xyz; texUv = TEXCOORD_0;
}





































// Name : EVBE_v0.8r-cubemap.vsh
// Notice : Some of code has been taken from the internet and Mojang.
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved to their respective owners.