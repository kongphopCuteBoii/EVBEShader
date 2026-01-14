// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "vertexVersionCentroidUV.h"

#include "uniformWorldConstants.h"
#include "uniformEntityConstants.h"
#include "libs/EVBE_lib.glsl"
#ifdef USE_SKINNING
    #include "uniformAnimationConstants.h"
#endif

attribute hp vec4 POSITION, NORMAL;
attribute vec2 TEXCOORD_0;
attribute vec4 COLOR;
#ifdef USE_SKINNING
    #ifdef MCPE_PLATFORM_NX
        attribute uint BONEID_0;
    #else
        attribute float BONEID_0;
    #endif
#endif

varying float baseLight;
varying vec4 light, fogColor;
varying hp vec3 wPos, cPos, normal;
flat varying int isNether, isTheEnd;
#ifdef COLOR_BASED
    varying vec4 vertColor;
#endif
#ifdef USE_OVERLAY
    varying hp vec4 overlayColor;
#endif
#ifdef TINTED_ALPHA_TEST
	varying float alphaTestMultiplier;
#endif
#ifdef GLINT
	varying vec2 layer1UV, layer2UV;
	varying vec4 tileLightColor, glintColor;
#endif

const float AMBIENT = 0.45;
const float XFAC = -0.1, ZFAC = 0.1;

float lightIntensity(vec4 pos, vec4 normal) {
    #ifdef FANCY
        vec3 N = normalize(mul(WORLD, normal)).xyz;
        N.y *= TILE_LIGHT_COLOR.w;
        #ifdef FLIP_BACKFACES
            vec3 viewDir = normalize(mul(WORLD, pos).xyz);
            if(dot(N, viewDir) > 0.0) N *= -1.0;
        #endif
        float yLight = (1.0+N.y)*0.5;
        yLight *= 1.0-AMBIENT;
        return yLight + N.x*N.x * XFAC + N.z*N.z * ZFAC + AMBIENT;
    #else
        return 1.0;
    #endif
}

#ifdef GLINT
    vec2 calculateLayerUV(float offset, float rotation) {
    	vec2 uv = TEXCOORD_0-0.5;
    	uv = mul(rot(rotation), uv);
    	uv += vec2(offset, 0)+0.5;
    	return uv*GLINT_UV_SCALE;
    }
#endif

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

void main() {
	POS4 entitySpacePosition;
	POS4 entitySpaceNormal;
	isNether = checkNether(), isTheEnd = checkTheEnd();

    #ifdef USE_SKINNING
    	#if defined(LARGE_VERTEX_SHADER_UNIFORMS)
    		entitySpacePosition = BONES[int(BONEID_0)] * POSITION;
    		entitySpaceNormal = BONES[int(BONEID_0)] * NORMAL;
    	#else
    		entitySpacePosition = BONE * POSITION;
    		entitySpaceNormal = BONE * NORMAL;
    	#endif
    #else
    	entitySpacePosition = POSITION * vec4(1, 1, 1, 1);
    	entitySpaceNormal = NORMAL * vec4(1, 1, 1, 0);
    #endif
    
	POS4 pos = WORLDVIEWPROJ*entitySpacePosition;
	gl_Position = pos;
	
	wPos = (WORLD*entitySpacePosition).xyz, cPos = POSITION.xyz,
	normal = normalize(WORLD*entitySpaceNormal).xyz;
	float L = lightIntensity(entitySpacePosition, entitySpaceNormal);

    #ifdef USE_OVERLAY
    	L += OVERLAY_COLOR.a * 0.35;
    #endif
    
    #ifdef TINTED_ALPHA_TEST
    	alphaTestMultiplier = OVERLAY_COLOR.a;
    #endif
    light = vec4(vec3(L)*TILE_LIGHT_COLOR.xyz, 1.0);
    #ifdef COLOR_BASED
    	vertColor = COLOR;
    #endif
    #ifdef USE_OVERLAY
    	overlayColor = OVERLAY_COLOR;
    #endif
    #ifndef NO_TEXTURE
    	uv = TEXCOORD_0;
    	baseLight = TILE_LIGHT_COLOR.r;
    #endif
    #ifdef USE_UV_ANIM
    	uv.xy = UV_ANIM.xy + (uv.xy * UV_ANIM.zw);
    #endif
    #ifdef GLINT
    	glintColor = GLINT_COLOR;
    	layer1UV = calculateLayerUV(UV_OFFSET.x, UV_ROTATION.x);
    	layer2UV = calculateLayerUV(UV_OFFSET.y, UV_ROTATION.y);
    	tileLightColor = TILE_LIGHT_COLOR;
    #endif

	fogColor.rgb = fc.rgb;
	fogColor.a = saturate(((pos.z/rd)-fcn.x)/(fcn.y-fcn.x));
}