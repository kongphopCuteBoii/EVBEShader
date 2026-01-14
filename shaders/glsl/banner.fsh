// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "fragmentVersionCentroid.h"
#include "uniformShaderConstants.h"
#include "uniformEntityConstants.h"
#include "libs/! config.glsl"
#include "libs/EVBE_lib.glsl"
#include "libs/EVBE_color.glsl"
#include "libs/EVBE_noise.glsl"

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;

varying hp vec3 wPos, cPos;
flat varying int isNether, isTheEnd;
#if __VERSION__ >= 300
    _centroid varying vec4 uv;
#else
    varying vec4 uv;
#endif
#ifdef ENABLE_FOG
    varying vec4 fogColor;
#endif
#ifdef ENABLE_LIGHT
    varying vec4 light;
#endif
#ifndef DISABLE_TINTING
    varying vec4 color;
#endif

#include "libs/EVBE_function.glsl"

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
	vec4 diffuse = texture2D(TEXTURE_0, uv.xy),
	     color = texture2D(TEXTURE_0, uv.zw);
	vec4 textureCol = diffuse*color;
    #ifndef DISABLE_TINTING
    	color.a = mix(diffuse.r*diffuse.a, diffuse.a, color.a);
    	color.rgb *= color.rgb;
    #endif
    #ifdef ENABLE_LIGHT
    	color.rgb *= light.rgb;
    #endif
    #ifdef ENABLE_FOG
    	color.rgb = mix(color.rgb, fogColor.rgb, fogColor.a);
    #endif
    #ifdef UI_ENTITY
    	color.a *= HUD_OPACITY;
    #endif
    bool world0 = (isNether+isTheEnd == 0),    // (i) Overworld
         world1 = (isNether == 1),             // (i) Nether
         world2 = (isTheEnd == 1);             // (i) The End
         
    hp vec3 wp = wPos, cp = cPos, np = normalize(wp);
    float uv1Y = smoothstep(0.0, 0.1, TILE_LIGHT_COLOR.b);
    float fakeE = saturate(pow(dot(textureCol.rg, vec2(0.5)), 2.0));
    vec2 lightMapParams = vec2(mix(smoothstep(1.0, 0.5, uv1Y), 1.0, max(night, rain*0.8)), fakeE);
    float lightMap = getLightMap(pow(TILE_LIGHT_COLOR.r, 8.0), lightMapParams);
    
    if(world0) {
        float shadows = 1.0-uv1Y;
        vec3 worldCol = getWorldColor(shadows);
        color.rgb  = color.rgb*worldCol+lightMap*vec3(2, 0.5, 0.1);
        
        color.rgb *= mix(uv1Y*0.75+0.25, 1.0, lightMap);
        color.rgb  = rainSaturation(color.rgb, uv1Y*0.7);
        #ifdef enableFog
            vec4 fog = getFog(color.rgb, wp, np, uv1Y);
            color.rgb = fog.rgb;
        #endif
        color.rgb = colorMask(color.rgb);
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