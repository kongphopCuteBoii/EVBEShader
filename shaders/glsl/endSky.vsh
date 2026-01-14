#include "vertexVersionCentroidUV.h"
#include "libs/EVBE_lib.glsl"
uniform MAT4 WORLDVIEWPROJ, WORLD;
attribute POS4 POSITION;
varying hp vec3 wPos;

void main() {
    gl_Position = WORLDVIEWPROJ*POSITION;
    wPos = mul(WORLD, POSITION).xyz;
}