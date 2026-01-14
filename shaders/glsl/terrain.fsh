// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "fragmentVersionCentroid.h"
#include "uniformShaderConstants.h"
#include "util.h"

#include "libs/! config.glsl"
#include "libs/EVBE_lib.glsl"
#include "libs/EVBE_color.glsl"
#include "libs/EVBE_noise.glsl"
LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;
LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;

varying vec4 color;
varying lp vec2 uv0, uv1;
varying float shadowsOrigin;
varying hp vec3 wPos, cPos, sPos;
flat varying int isWater, isNether, isTheEnd;

#define terrainShader
#include "libs/EVBE_function.glsl"
#include "libs/EVBE_FXAA.glsl"

// (i) Materials
bool isUnderwater(float uv1Y, float cpY) {
    float threshold = 0.9, epsilon = 0.00005;
    return uv1Y < threshold && abs((2.0*cpY-15.0)*0.0625-uv1Y) < epsilon;
}
float getLightMap(float x, vec2 emissive) {
    float l = saturate(1.0-x)*14.0+2.5;
    float attenuation = min1(1.0/(l*l*l));
    return attenuation*emissive.x*(emissive.y*400.0);
}
float getWave(hp vec2 pos) {
    float normalY = -normalize(wPos).y*6.0;
    if(fcn.x == 0.0) normalY = -normalY;
    normalY = smoother(normalY);
    if(normalY <= 0.0) return 0.0; else {
        pos += pos.yx*0.4;
        pos += sin((pos.x+pos.y)+cos(pos.y+pos.x))*0.1+tm;
        return sin(noise2D(pos+tm)+noise2D(pos*2.5-tm)*0.5)*normalY;
    }
}
float getCaustic(hp vec2 pos) {
    float tmi = tm*0.2;
    pos += pos.yx*0.2;
    pos += sin((pos.x+pos.y)+cos(pos.y+pos.x))*0.1+tm;
    return sin(wnoise(pos+tmi)+wnoise(pos*2.0-tmi)*0.5);
}
#ifdef enableAO
    vec3 colAOadjuster(vec3 col, float ints) {
        bool t0 = col.g*1.9 > col.r+col.b;
        if(ints==1.0) return col; else
        if(ints==0.0) return t0 ? normalize(col) : vec3(1); else {
            col = t0 ? mix(normalize(col), col, ints) : mix(vec3(1), col, ints);
            #ifdef ALPHA_TEST
                col = (col.b==0.0) ? col : vec3(1);
            #endif
            return col;
        }
    }
#else
    vec3 colAOadjuster(vec3 col, float ints) {
        bool t0 = col.g*1.9 > col.r+col.b;
        return t0 ? normalize(col) : vec3(1);
    }
#endif
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
vec4 getTextureCol(lp vec2 uv) {
    vec4 textureCol = vec4(0);
    #if USE_TEXEL_AA
        textureCol = texture2D_AA(TEXTURE_0, uv);
    #else
        textureCol = texture2D(TEXTURE_0, uv);
    #endif
    #ifdef enableFXAA
        textureCol.rgb = fastApproximateAA(TEXTURE_0, gl_FragCoord.xy, sPos.xy, uv, textureCol.rgb);
    #endif
    return textureCol;
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
    
    albedo = mix(albedo, fCol, fLight*mix(0.4, 0.9, fHeight));
    if(fLimit > 0.0) 
        albedo = mix(albedo, getAestheticSky(np, 1), fLimit);
    #ifdef fakeSunBloom
        albedo = mix(albedo, miePhase.rgb, miePhase.a*(1.0-max(fLight, fLimit))*lightMap);
    #endif
    return vec4(albedo, fLimit);
}

// (i) Normal Mapping
hp vec3 getNormalBase(hp vec3 wp) {
    hp vec3 b0 = dFdx(wp), b1 = dFdy(wp);
    return normalize(cross(b0, b1));
}
hp vec3 wave2Normal(hp vec2 pos) {
	float b0 = getWave(pos),
	      b1 = getWave(pos+vec2(0.1, 0.0)),
	      b2 = getWave(pos+vec2(0.0, 0.1));
	vec2 c0 = vec2(b1-b0, b2-b0)*0.5;
	float resultFactor = abs(c0.x+c0.g);
	vec3 result = vec3(c0, 1.0-resultFactor*resultFactor);
	return normalize(result);
}
hp vec3 getNormalMap(lp vec2 uv, hp vec2 cp) {
    vec3 mapBase = getTextureCol(uv+vec2(normalValue, 0)).rgb;
    if(isWater == 1) return wave2Normal(cp);
    if(mapBase.b == 0.0 && (isWater == 0))
        return vec3(0, 0, 1); else {
            mapBase.rg = mapBase.rg*2.0-1.0;
            mapBase.b = sqrt(1.0-dot(mapBase.rg, mapBase.rg));
            return normalize(mapBase);
    }
}
hp vec3 getTangent(hp vec3 n) {
    hp vec3 t = vec3(0);
	     if(n.x > 0.0) t = vec3(0, 0, -1); else if(n.x < -0.5) t = vec3( 0, 0, 1);
	else if(n.y > 0.0) t = vec3(1, 0,  0); else if(n.y < -0.5) t = vec3( 1, 0, 0);
	else if(n.z > 0.0) t = vec3(1, 0,  0); else if(n.z < -0.5) t = vec3(-1, 0, 0);
	return t;
}
hp mat3 getTBNMatrix(hp vec3 N) {
    hp vec3 T = getTangent(N),
            B = normalize(cross(T, N));
    return transpose(mat3(T, B, N));
}

// (i) GGX Distribution
hp float getGeometric(hp float NdV, float pbrG) {
    hp float k = pow(pbrG+1.0, 2.0)*0.125;
    return 1.0/(NdV*(1.0-k)+k);
}
hp float getSpecular(hp float NdH, float pbrG, float pbrR) {
    hp float a = pbrG*pbrG, f = mix(0.04, 1.0, pow(1.0-NdH, 5.0));
    return f*(a*NdH)/(pow(NdH*NdH*(a*a-1.0)+1.0, 2.0));
}
hp float sGGX(vec3 lightDir, hp vec3 viewDir, hp vec3 N, float pbrG, float pbrR) {
    hp vec3 halfDir = normalize(lightDir+viewDir);
    hp float NdH = max0(dot(N, halfDir)),
             NdV = max0(dot(N, viewDir)),
             NdL = max0(dot(N, lightDir));
    hp float g = getGeometric(NdV, pbrG), s = getSpecular(NdH, pbrG, pbrR);
    return NdL*g*s;
}
hp vec4 getGGX(hp vec3 wp, hp vec3 normalMap, vec2 surface, int v) {
    hp vec3 viewDir = normalize(-wp);
    if(v == 0) {
        hp vec4 sCol = vec4(sGGX(sunAngle, viewDir, normalMap, surface.x, surface.y));
        sCol.rgb *= getTimeColor(sunAngle.y, vec3(1), vec3(0));
        hp vec4 mCol = vec4(sGGX(moonAngle, viewDir, normalMap, surface.x, surface.y));
        mCol.rgb *= vec3(0.6, 0.8, 1.1);
        return sCol+(mCol*max(dusk*0.5, night));
    } else {
        vec3 endLight = normalize(vec3(0.5, 0.8, 0.5));
        hp vec4 eCol = vec4(sGGX(endLight, viewDir, normalMap, surface.x, surface.y));
        eCol.rgb *= vec3(1.155, 0.93, 1.155);
        return eCol;
    }
}

// (i) Reflection
vec4 getReflection(hp vec3 np, hp vec3 n, vec4 al, vec3 tCol, float pbrR, float pbrS, float exception, int v) {
    if(pbrR > 0.0) {
        hp vec3 rPos = reflect(np, n); float NdV = dot(n, normalize(-np));
        vec3 rCol = vec3(0);
        if(v == 0)
            rCol = getAestheticSky(rPos, 1-isWater);
        else
            rCol = theEndSky(rPos, rPos/rPos.y, 1-isWater);
        rCol = mix(rCol, rCol*tCol, pbrR);
        al.rgb *= mix(1.0, 0.5, pbrR*exception);
        al = mix(al, vec4(rCol, 1), pbrS*exception);
    }
    return al;
}

// (i) Water
float waterOpacity(hp float r, float lightFactor){
    float clearRange = mix(0.65, 0.4, smoother(r*0.83)),
          transparentRange = smoother(r*1.53);
    float wOpacity = mix(0.9, clearRange, transparentRange);
    return mix(wOpacity, 0.7, lightFactor);
}
vec3 getShadowsWater(vec3 albedo, vec2 lightmap, hp float rnpY) {
    float gradientRange = smoother(rnpY);
    vec3 caveWaterColorBase = vec3(0.05, 0.15, 0.25);
    return mix(albedo*mix(1.0, 0.5, lightmap.x), caveWaterColorBase*mix(0.75, 1.25, gradientRange), lightmap.y);
}

void main() {
#ifndef BYPASS_PIXEL_SHADER
    bool world0 = (isNether+isTheEnd == 0),    // (i) Overworld
         world1 = (isNether == 1),             // (i) Nether
         world2 = (isTheEnd == 1);             // (i) The End

    hp vec3 wp = wPos, cp = cPos, np = normalize(wPos);
    hp vec3 acPos = abs(cp-8.0);
    if(fcn.x == 0.0) np.y = -np.y;
    
    hp vec3 normal = getNormalBase(wp); hp mat3 TBN = getTBNMatrix(normal);
    hp vec3 rawNormal = getNormalMap(uv0, cp.xz); 
    normal = mul(TBN, rawNormal);
    
    vec4 col = color;
    vec4 textureCol = getTextureCol(uv0), dCol = getTextureCol(uv0+vec2(detectionValue, 0));
    float underwater = float(isUnderwater(uv1.y, cp.y))*uv1.y;
    
    #ifdef enablePBR
        vec4 pbrMap = textureLod(TEXTURE_0, uv0+vec2(pbrValue, 0.0), 0.0);
    #else
        vec4 pbrMap = vec4(0, 0, 0, 1);
    #endif
    if(isWater == 1)
        pbrMap.rg = vec2(1);
    #ifdef enableWetEffect
        float puddleNoise = smoothstep(0.6, 0.9, noise2D(acPos.xz*0.8));
        puddleNoise *= max0(normal.y)*rain;
        pbrMap.rg = max(pbrMap.rg, puddleNoise*vec2(0.3, 0.9));
    #endif
    float pbrE = ((pbrMap.a*255.0) < 254.5) ? pbrMap.a : 0.0,
          pbrR = pbrMap.g, pbrS = pbrMap.r, pbrG = pow(1.0-pbrS, 2.0);
    float fakeE = saturate(pow(dot(textureCol.rg, vec2(0.5)), 2.0));
    
    vec2 lightMapParams = vec2(mix(smoothstep(1.0, 0.5, uv1.y), 1.0, max(night, rain*0.8)), mix(fakeE, pbrE, 0.5));
    float lightMap = getLightMap(uv1.x, lightMapParams);

    vec4 albedo = textureCol;
    #if USE_ALPHA_TEST
        if(albedo.a <
            #ifdef ALPHA_TO_COVERAGE
	            0.05
            #else
	            0.5
            #endif
        ) {
	        discard; return;
        }
    #endif
    
    vec3 lowLODal = textureLod(TEXTURE_0, uv0, 2.0).rgb;
    float aoSpace = pow(1.0-luminance(lowLODal*col.rgb), aoIntensity);
    #ifdef SEASONS
        albedo = vec4(albedo.rgb*mix(textureLod(TEXTURE_2, col.xy, 0.0).rgb*2.0, vec3(1.5), rain)*pow(col.a, 0.2), 1.0);
    #else
        albedo.rgb *= mix(colAOadjuster(col.rgb, 0.0), col.rgb, aoSpace);
    #endif
    vec3 textureColored = (isWater == 1) ? mix(col.rgb, vec3(1), 0.0) : albedo.rgb;
    
    if(world0) {
        // (i) Get shadows
        hp float isShadows = smoothstep(shadowsOrigin, shadowsOrigin-0.02, uv1.y),
                 normalShadows = saturate(dot(mix(normal, getNormalBase(cp), 0.5), -lightAngle)*3.0)
        #ifdef ALPHA_TEST
                               * (1.0+normal.y)
        #endif
        ,        coverageShadows = 0.0
        #ifdef ALPHA_TEST
                                 + smoothstep(0.45, 0.41, col.g)
                                 - saturate(abs(normal.x))
        #endif
        ;
        isShadows  = max(isShadows, ((dCol.r == 1.0) ? smoothstep(0.75, 0.0, fract(cp).y)*0.6 : 0.0));
        hp float shadows  = max(max(isShadows, normalShadows), coverageShadows);
        shadows -= underwater, isShadows -= underwater;
        
        // (i) Albedo zone
        hp vec3 reflected = reflect(np, normal);
        float shadowsValues = mix(shadows, smoothstep(0.9, 0.5, uv1.y), 0.3)-min1(lightMap);
        vec3 worldCol = getWorldColor(shadowsValues),
             wAbspCol = abspCol(smoothstep(0.8, 0.4, uv1.y), vec3(6.0, 0.6, 0.0));
        albedo.rgb = worldCol*albedo.rgb*mix(vec3(1), wAbspCol, underwater)+lightMap*vec3(2, 0.5, 0.1);
        
        if(isWater == 1) {
            albedo.a = waterOpacity(reflected.y, smoothstep(0.5, 0.0, uv1.y));
            albedo.rgb = getReflection(np, normal, albedo, vec3(1), pbrR, pbrS, 1.0, 0).rgb;
            
            hp vec4 GGX = saturate(getGGX(np, normal, vec2(0.02, pbrR), 0))*(1.0-isShadows); albedo += GGX;
            albedo.rgb = getShadowsWater(albedo.rgb, vec2(isShadows, 1.0-uv1.y), reflected.y);
        } else {
            float reflectionFactor = mix(1.0-isShadows, smoothstep(0.5, 1.0, uv1.y), rain);
            albedo  = getReflection(np, normal, albedo, textureColored, pbrR, pbrS, reflectionFactor, 0);
            albedo += saturate(getGGX(np, normal, vec2(pbrG, pbrR), 0))*reflectionFactor;
        }
        albedo.rgb *= mix(uv1.y*0.75+0.25, 1.0, lightMap);
        albedo.rgb = rainSaturation(albedo.rgb, uv1.y*0.7);
        
        #ifdef enableCaustic
            if(underwater > 0.0) {
                float caustic = smoother(pow(getCaustic(cp.xz*1.4), 2.0));
                albedo.rgb *= 1.0+(caustic*underwater);
            }
        #endif
        
        // (i) Fog
        #ifdef enableFog
            vec4 fog = getFog(albedo.rgb, wp, np, uv1.y);
            if(fog.a == 1.0) { discard; return; }
            albedo.rgb = colorMask(fog.rgb);
        #endif
    } else if(world1) {
        #ifdef soulValleyBlueLight
            float soulSandValley = smoothstep(0.1, 0.2, fc.b)-smoothstep(0.35, 0.4, fc.b);
        #else
            float soulSandValley = 0.0;
        #endif
        vec3 ambientCol = vec3(0.3, 0.32, 0.34),
             lightCol   = mix(vec3(2, 0.5, 0.1), vec3(0.1, 1, 2)*3.0, soulSandValley);
        albedo.rgb = albedo.rgb*ambientCol+lightCol*lightMap;
        #ifdef enableFog
            float fogFactor = length(wp);
            float fogDist = smoothstep(0.0, rd*0.7, fogFactor);
            albedo.rgb = mix(colorMask(albedo.rgb), fc.rgb, fogDist);
        #endif
    } else if(world2) {
        vec3 endLight = normalize(vec3(0.5, 0.8, 0.5));
        float dirlight = saturate(dot(-endLight, normal)*3.0);
        albedo.rgb *= mix(vec3(1), vec3(0.8, 0.6, 0.8), dirlight);
        albedo.rgb = albedo.rgb*vec3(0.5, 0.35, 0.5)+vec3(1)*lightMap;
        
        hp vec3 reflected = reflect(np, normal);
        if(isWater == 1) {
            albedo.a = waterOpacity(reflected.y, 0.0);
            albedo.rgb = getReflection(np, normal, albedo, vec3(1), pbrR, pbrS, 1.0, 1).rgb;
            hp vec4 GGX = saturate(getGGX(np, normal, vec2(0.02, pbrR), 1)); albedo += GGX;
            albedo.rgb = getShadowsWater(albedo.rgb, vec2(0), reflected.y);
        } else {
            albedo  = getReflection(np, normal, albedo, textureColored, pbrR, pbrS, 1.0, 1);
            albedo += saturate(getGGX(np, normal, vec2(pbrG, pbrR), 1));
        }
        
        #ifdef enableFog
            #ifdef fakeSunBloom
                float lightDot = smoothstep(0.0, 2.5, dot(np, endLight));
                lightDot *= 1.5;
                vec3 lightCol = vec3(1.155, 0.93, 1.155);
                albedo.rgb = mix(albedo.rgb, lightCol, lightDot);
            #endif
            float fogRange = smoothstep(0.0, rd*0.5, length(wp)),
                  fogHeight = smoothstep(0.5, 0.0, np.y);
            albedo.rgb = mix(albedo.rgb, theEndSky(np, np/np.y, 1), fogRange*fogHeight);
            albedo.rgb = colorMask(albedo.rgb);
        #endif
    } else { discard; return; }
    
    
    //albedo.rgb = getTextureCol(uv0+vec2(normalValue, 0)).rgb;
    gl_FragColor = albedo;

#endif // BYPASS_PIXEL_SHADER
}




































// Name : EVBE_v0.8r-terrain.fsh
// Notice : Some of code has been taken from the internet and Mojang.
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved to their respective owners.