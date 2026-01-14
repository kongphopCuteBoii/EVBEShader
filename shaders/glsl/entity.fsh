// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.


#include "fragmentVersionCentroidUV.h"

#include "libs/! config.glsl"
#include "libs/EVBE_lib.glsl"
#include "libs/EVBE_color.glsl"
#include "libs/EVBE_noise.glsl"
#include "uniformEntityConstants.h"
#include "uniformShaderConstants.h"
#include "util.h"

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;

#ifdef USE_MULTITEXTURE
	LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;
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

#include "libs/EVBE_function.glsl"
vec4 glintBlend(vec4 dest, vec4 source) {
	return vec4(source.rgb*source.rgb, 
	            abs(source.a)) + vec4(dest.rgb, 0.0);
}

#ifdef USE_EMISSIVE
#ifdef USE_ONLY_EMISSIVE
#define NEEDS_DISCARD(C) (C.a == 0.0 || C.a == 1.0 )
#else
#define NEEDS_DISCARD(C)	(C.a + C.r + C.g + C.b == 0.0)
#endif
#else
#ifndef USE_COLOR_MASK
#define NEEDS_DISCARD(C)	(C.a < 0.5)
#else
#define NEEDS_DISCARD(C)	(C.a == 0.0)
#endif
#endif

// (i) Materials
float getLightMap(float x, vec2 emissive) {
    float l = saturate(1.0-x)*14.0+2.5;
    float attenuation = min1(1.0/(l*l*l));
    return attenuation*emissive.x*(emissive.y*400.0);
}
vec3 getShadowsColor(float depth) {
    vec3 sCol = vec3(0.1, 0.25, 0.4);
    sCol = mix(mix(sCol, vec3(0.1, 0.4, 0.8), smoothstep(0.6, 0.1, depth)),
                         vec3(0.2, 0.3, 0.6), smoothstep(0.2, 0.0, depth));
    return sCol;
}
vec3 getWorldColor(float isShadows) {
    vec3 shadowsColor = getShadowsColor(sunAngle.y),
         ambientColor = getTimeColor(sunAngle.y)*(1.0-rain*0.4);
    return mix(ambientColor, shadowsColor, isShadows);
}
vec4 getFog(vec3 albedo, hp vec3 wp, hp vec3 np, float lightMap) {
    float fDistance = rd*(1.0-max(rain, float(fcn.x == 0.0))*0.8);
    float fLight = smoothstep(0.0, fDistance*0.7, length(wp));
    #ifdef unloadedChunksFog
        float fLimit = smoothstep(rd*0.95, rd, length(wp));
    #else
        float fLimit = 0.0;
    #endif
    float fHeight = smoothstep(0.5, -0.5, np.y);
    
    fHeight = mix(fHeight, 1.0, rain*0.7);
    vec3 fCol = rainSaturation(getSkyColor(vec3(0, 0.15, 0)), 1.0);
    #ifdef fakeSunBloom
        vec3 sCol = getTimeColor(sunAngle.y)*2.0, mCol = vec3(0.4, 0.8, 1.1);
        float sPhase = simpleMiePhase0(np, 1, 0.4, 3.0),
              mPhase = simpleMiePhase0(np, 0, 0.4, 2.5);
        vec4 miePhase = mix(vec4(sCol, sPhase), vec4(mCol, mPhase), night);
        miePhase.rgb = rainSaturation(miePhase.rgb, 1.0);
        fCol = mix(fCol, miePhase.rgb, min1(miePhase.a*3.0));
    #endif
    
    albedo = mix(albedo, fCol, fLight*mix(0.4, 0.9, fHeight)*(1.0-fLimit));
    if(fLimit > 0.0) 
        albedo = mix(albedo, getAestheticSky(np, 1), fLimit);
    #ifdef fakeSunBloom
        albedo = mix(albedo, miePhase.rgb, miePhase.a*(1.0-max(fLight, fLimit))*lightMap);
    #endif
    return vec4(albedo, fLimit);
}

void main() {
    vec4 color = vec4(1), 
         textureCol = vec4(1);
    #ifndef NO_TEXTURE
        textureCol = textureLod(TEXTURE_0, uv, 0.0);
        color = textureCol;
        #ifdef MASKED_MULTITEXTURE
        	vec4 tex1 = texture2D( TEXTURE_1, uv );
        	float maskedTexture = float(dot( tex1.rgb, vec3(1.0, 1.0, 1.0) ) * ( 1.0 - tex1.a ) > 0.0);
        	color = mix(tex1, color, maskedTexture);
        #endif
        #if defined(ALPHA_TEST) && !defined(USE_MULTITEXTURE) && !defined(MULTIPLICATIVE_TINT)
        	if(NEEDS_DISCARD(color)) {
        		discard; return;
        	}
        #endif
        #ifdef TINTED_ALPHA_TEST
            vec4 testColor = color;
            testColor.a *= alphaTestMultiplier;
            if(NEEDS_DISCARD(testColor)) {
            	discard; return;
            }
        #endif
    #endif
    #ifdef COLOR_BASED
    	color *= vertColor;
    #endif
    #ifdef MULTI_COLOR_TINT
    	vec2 colorMask = color.rg;
    	color.rgb = colorMask.rrr * CHANGE_COLOR.rgb;
    	color.rgb = mix(color, colorMask.gggg * MULTIPLICATIVE_TINT_CHANGE_COLOR, ceil(colorMask.g)).rgb;
    #else
        #ifdef USE_COLOR_MASK
        	color.rgb = mix(color.rgb, color.rgb*CHANGE_COLOR.rgb, color.a);
        	color.a *= CHANGE_COLOR.a;
        #endif
        #ifdef ITEM_IN_HAND
        	color.rgb = mix(color.rgb, color.rgb*CHANGE_COLOR.rgb, vertColor.a);
            #if defined(MCPE_PLATFORM_NX) && defined(NO_TEXTURE) && defined(GLINT)
            	vec3 dummyColor = texture2D(TEXTURE_0, vec2(0.0, 0.0)).rgb;
            	color.rgb += dummyColor * 0.000000001;
            #endif
        #endif
    #endif
    #ifdef USE_MULTITEXTURE
    	vec4 tex1 = texture2D( TEXTURE_1, uv );
    	vec4 tex2 = texture2D( TEXTURE_2, uv );
    	color.rgb = mix(color.rgb, tex1.rgb, tex1.a);
        #ifdef ALPHA_TEST
        	if (color.a < 0.5 && tex1.a == 0.0) {
        		discard; return;
        	}
        #endif
        #ifdef COLOR_SECOND_TEXTURE
        	if (tex2.a > 0.0)
        		color.rgb = tex2.rgb + (tex2.rgb * CHANGE_COLOR.rgb - tex2.rgb)*tex2.a;
        #else
        	color.rgb = mix(color.rgb, tex2.rgb, tex2.a);
        #endif
    #endif
    #ifdef MULTIPLICATIVE_TINT
    	vec4 tintTex = texture2D(TEXTURE_1, uv);
        #ifdef MULTIPLICATIVE_TINT_COLOR
        	tintTex.rgb = tintTex.rgb * MULTIPLICATIVE_TINT_CHANGE_COLOR.*;
        #endif
        #ifdef ALPHA_TEST
        	color.rgb = mix(color.rgb, tintTex.rgb, tintTex.a);
        	if (color.a + tintTex.a <= 0.0) {
        		discard; return;
        	}
        #endif
    #endif
    #ifdef USE_OVERLAY
    	color.rgb = mix(color, overlayColor, overlayColor.a).rgb;
    #endif
    #ifdef USE_EMISSIVE
    	color *= mix(vec4(1.0), light, color.a);
    #endif
    #ifdef GLINT
    	vec4 layer1 = texture2D(TEXTURE_1, fract(layer1UV)).rgbr * glintColor;
    	vec4 layer2 = texture2D(TEXTURE_1, fract(layer2UV)).rgbr * glintColor;
    	vec4 glint = (layer1 + layer2) * tileLightColor;
    	color = glintBlend(color, glint);
    #endif
    #ifdef UI_ENTITY
    	color.a *= HUD_OPACITY;
    #endif
    vec3 c = color.rgb;
    
    bool world0 = (isNether+isTheEnd == 0),    // (i) Overworld
         world1 = (isNether == 1),             // (i) Nether
         world2 = (isTheEnd == 1);             // (i) The End
         
    hp vec3 wp = wPos, cp = cPos, np = normalize(wp);
    float uv1Y = smoothstep(0.0, 0.1, TILE_LIGHT_COLOR.b);
    float fakeE = saturate(pow(dot(textureCol.rg, vec2(0.5)), 2.0));
    vec2 lightMapParams = vec2(mix(smoothstep(1.0, 0.5, uv1Y), 1.0, max(night, rain*0.8)), fakeE);
    float lightMap = getLightMap(pow(TILE_LIGHT_COLOR.r, 8.0), lightMapParams);
    
    if(world0) {
        float isShadows = 1.0-uv1Y,
              normalShadows = saturate(dot(normal, -lightAngle)*3.0);
        float shadows = max(isShadows, normalShadows);
        vec3 worldCol = getWorldColor(shadows);
        color.rgb  = color.rgb*worldCol+lightMap*vec3(2, 0.5, 0.1);
        
        color.rgb *= mix(uv1Y*0.75+0.25, 1.0, lightMap);
        color.rgb  = rainSaturation(color.rgb, uv1Y*0.7);
        vec4 fog = getFog(color.rgb*0.7, wp, np, uv1Y);
        if(fog.a >= 1.0) {
            #ifdef RBlobbyLight
                color.rgb = c;
                float side = abs(dot(normal, vec3(1, 0, 0)));
                color.rgb = mix(color.rgb, vec3(normal.x, 0, normal.z), side*0.3+0.2);
            #endif
        } else {
            #ifdef enableFog
                color.rgb = fog.rgb;
            #endif
            color.rgb = colorMask(color.rgb);
        }
    } else if(world1) {
        #ifdef soulValleyBlueLight
            float soulSandValley = smoothstep(0.1, 0.2, fc.b)-smoothstep(0.35, 0.4, fc.b);
        #else
            float soulSandValley = 0.0;
        #endif
        vec3 ambientCol = vec3(0.3, 0.32, 0.34),
             lightCol   = mix(vec3(2, 0.5, 0.1), vec3(0.1, 1, 2)*3.0, soulSandValley);
        color.rgb = color.rgb*ambientCol+lightCol*lightMap;
        color.rgb = colorMask(color.rgb);
        #ifdef enableFog
            float fogFactor = length(wp);
            float fogDist = smoothstep(0.0, rd*0.5, fogFactor);
            color.rgb = mix(color.rgb, fc.rgb, fogDist);
        #endif
    } else if(world2) {
        vec3 endLight = normalize(vec3(0.5, 0.8, 0.5));
        float dirlight = saturate(dot(-endLight, normal)*3.0);
        color.rgb *= mix(vec3(1), vec3(0.8, 0.6, 0.8), dirlight);
        color.rgb  = color.rgb*vec3(0.5, 0.35, 0.5)+lightMap;
        #ifdef enableFog
            #ifdef fakeSunBloom
                float lightDot = smoothstep(0.0, 2.5, dot(np, endLight));
                lightDot *= 1.5;
                vec3 lightCol = vec3(1.155, 0.93, 1.155);
                color.rgb = mix(color.rgb, lightCol, lightDot);
            #endif
            
            float fogRange = smoothstep(0.0, rd*0.3, length(wp)),
                  fogHeight = smoothstep(0.5, 0.0, np.y);
            color.rgb = mix(color.rgb, theEndSky(np, np/np.y, 1), fogRange*fogHeight);
        #endif
        color.rgb = colorMask(color.rgb);
    } else { discard; return; }
	gl_FragColor = color;
}
