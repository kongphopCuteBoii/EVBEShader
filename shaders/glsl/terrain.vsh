// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "vertexVersionCentroid.h"

#include "uniformWorldConstants.h"
#include "uniformShaderConstants.h"
#include "uniformRenderChunkConstants.h"
#include "libs/! config.glsl"
#include "libs/EVBE_lib.glsl"
#include "libs/EVBE_color.glsl"
#include "libs/EVBE_noise.glsl"

attribute hp vec4 POSITION;
attribute vec4 COLOR;
attribute lp vec2 TEXCOORD_0, TEXCOORD_1;
uniform float FAR_CHUNKS_DISTANCE;
uniform sampler2D TEXTURE_0;

varying vec4 color;
varying lp vec2 uv0, uv1;
varying float shadowsOrigin;
varying hp vec3 wPos, cPos, sPos;
flat varying int isWater, isNether, isTheEnd;

bool getLeaves(vec4 col) {
	bool colA = col.g > min(col.r, col.b), 
	     colB = (col.r == col.g && col.r == col.b),
	     colC = (col.a < 0.005) && max(col.r, col.g) > 0.37;
	bool areLeaves = (colA || !colB) || colC;
	return areLeaves;
}
bool getPlants(vec4 col, hp vec3 fp) {
    #if defined(ALPHA_TEST)
        bool colFactor = (col.g != col.b) && (col.g+col.b > col.r),
             posFactor = fp.y == 0.9375 && (fp.z == 0.0 || fp.x == 0.0);
        return colFactor || posFactor;
    #else
        return false;
    #endif
}
int checkTheEnd() {
	bool theEnd = (fc.r == fc.g) && (fc.g > fc.b);
	return int(theEnd);
}
int checkNether() {
	float fcnFactor = fcn.x/fcn.y;
	float a = step(0.10, fcnFactor),
	      b = step(0.12, fcnFactor);
	float nether = a-b;
	return int(nether);
}
float wavePlants(hp vec3 cp, vec2 lightmap, int e) {
	hp vec3 fp = fract(cp), ap = abs(cp-8.0);
	if(e != 1) ap.z = ap.x;
	
	float waveA = cos(tm*0.01+ap.x),
	      waveB = sin(tm*3.15+2.25*ap.z+ap.y);
	float windFactor = dot(vec4(ap, tm), vec4(0.2, 0.2, 0.2, 1.2));
    float wave = waveA+waveB, wind = cos(tm+windFactor);
    
    wave *= 0.001+(0.049*lightmap.y); wind *= 1.0+rain;
	return clamp(wave*wind, -0.5, 1.0);
}

void main() {
    uv0 = TEXCOORD_0, uv1 = TEXCOORD_1;
    cPos = POSITION.xyz; color = COLOR;
    hp vec3 cp = cPos, bp = fract(cp);
    
    isWater = 0;
    isNether = checkNether(), isTheEnd = checkTheEnd();
    #if (defined(BLEND) || defined(FOG)) && !defined(SEASONS)
        isWater = int(color.r<color.b);
    #endif
    if(getLeaves(color) || (bp.y==0.5 && bp.x==0.0) || bool(shStyle))
        shadowsOrigin = 0.87;
    else shadowsOrigin = 0.898;
    
    #ifdef AS_ENTITY_RENDERER
	    hp vec4 pos = WORLDVIEWPROJ*cPos;
	    wPos = pos.xyz;
    #else
        wPos = (cPos*CHUNK_ORIGIN_AND_SCALE.w)+CHUNK_ORIGIN_AND_SCALE.xyz;
        hp vec4 pos = vec4(wPos, 1);
        
        if(getPlants(color, bp)) pos.xyz += wavePlants(cp, uv1, 0)*vec3(3, 0.7, 3);
        if(isWater == 1) pos.y += wavePlants(cp, uv1, 1)*hPi;
        pos = PROJ*(WORLDVIEW*pos);
    #endif
    
    sPos = vec3(pos.xy/(pos.z+1.0), pos.z);
    gl_Position = pos;
}







































// Name : EVBE_v0.8r-terrain.vsh
// Notice : Some of code has been taken from the internet and Mojang.
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved to their respective owners.