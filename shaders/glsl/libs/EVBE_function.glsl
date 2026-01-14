// [!] You should not make a change here if you have no idea to edit this properly.
// (i) Absorption and phases
vec3 abspCol(float x, vec3 a) {
    return exp(-x*a);
}
float simpleMiePhase(float mBase) {
    return smoother(1.0-pow(mBase, 0.1));
}
float simpleMiePhase0(vec3 p, int sm, float s, float e) {
    float mBase = dot(p, (sm == 1 ? sunAngle : moonAngle));
    return smoothstep(s, e, mBase);
}

// (i) Time Color
vec3 getTimeColor(float depth, vec3 c0, vec3 c4) {
    vec3 c1 = vec3(1.5, 0.6, 0.15), c2 = vec3(1.0, 0.3, 0.3), c3 = vec3(0.4, 0.16, 0.2);
    float sDepth0 = smoothstep(0.7, 0.2, depth),
          sDepth1 = smoothstep(0.5, 0.0, depth),
          sDepth2 = smoothstep(0.1, 0.0, depth);
    vec3 tColU = mix(c0, c1, sDepth0),
         tColD = mix(c2, c3, sDepth2);
    vec3 tCol = mix(tColU, tColD, sDepth1);
    return mix(tCol, c4, smoothstep(0.0, -0.1, depth));
}
vec3 getTimeColor(float depth) {
    return getTimeColor(depth, vec3(1), vec3(0.2, 0.4, 0.55));
}

// (i) Stars
float getStars(hp vec3 np) {
    np -= moonAngle*0.5;
    np = floor(np*300.0);
    return smoothstep(0.9975, 1.0, random3D(np));
}
hp float getStarFalls(hp vec2 fp, float fSpeed){
    fp.y += tm*sShootingSpeed;
	float starFalls = smoothstep(0.0, 0.3, noise2D(fp))*200.0;
	return 1.0-starFalls;
}
hp float getShootingStars(hp vec2 p){
    vec2 offset1 = vec2(0.3, 0.8),
         offset2 = vec2(0.14, 0.8),
         offset3 = vec2(0.16, 0.2);
    float smoothStar1 = getStarFalls((p - offset1) * 3.0, 1.25),
          smoothStar2 = getStarFalls((p - vec2(0.0, 0.7)) * 2.0, 2.0),
          smoothStar3 = getStarFalls((p - offset2) * 3.0, 1.2),
          smoothStar4 = getStarFalls((p - offset3) * 2.0, 3.0);
    float maxStars1 = max(smoothStar1, smoothStar2),
          maxStars2 = max(smoothStar3, smoothStar4);
    return smoother(max(maxStars1, maxStars2));
}

// (i) Sun/Moon
float getSM(hp vec3 np, int SM) {
    float base = 0.0, shape = 0.0;
    if(bool(SM)) {
        base  = distance(np, sunAngle),
        shape = smoothstep(0.03, 0.025, base);
    } else {
        base  = distance(np, moonAngle),
        shape = smoothstep(0.02, 0.01, base);
    }
    float mie = simpleMiePhase(base)*3.0;
    return saturate(shape*0.8+mie);
}

// (i) Aurora Borealis
vec3 auroraBorealis(vec2 np, vec3 al, float xc) {
	  vec3 upperColor = vec3(0, 0.5, 1),
	       lowerColor = vec3(0, 1, 0.3);
	  float aGradation = 0.0, aOpacity = 0.2;
	  vec2 ap = np; vec3 aCol = upperColor; vec3 cAl = al;

	  const int steps = 10;
	  float aGradationP = 0.02,
	        aOpacityP = 0.12, apM = 0.975;
	  for(int i = 0; i < steps; i++) {
	  	  aCol = mix(aCol, lowerColor, aGradation);
	  	  float aCurrentBase = triNoise2d(ap, 0.5)*aOpacity;
	  	  aCurrentBase = smoothstep(0.02, 1.0, aCurrentBase);
	  	  al = mix(al, aCol, aCurrentBase);
	  	  aGradation += aGradationP, aOpacity += aOpacityP;
	  	  ap *= apM;
	  }
    return mix(cAl, al, xc);
}


// (i) Sky materials
void getSkyDepth(hp float npY, out hp vec2 sDepth) {
    npY += npY;
    sDepth = pow(vec2(smoothstep(0.0, 2.5, abs(npY+0.35)),
                      smoothstep(0.5, 0.0, npY)), vec2(0.5, 2));
}
float getSkyPos(hp float depth, float uS) {
    return mix(-depth+ -depth, depth, uS);
}
float getUpperSky(hp float npY) {
    return smoothstep(-0.02, 0.02, npY);
}

// (i) Skies
vec3 getSkyColor(hp vec3 np) {
    float upperSky = getUpperSky(np.y);
    float skyPos = getSkyPos(np.y, upperSky);

    vec2 sDepth; getSkyDepth(skyPos, sDepth);
    vec3 skyColD = vec3(0.13, 0.21, 0.3), skyColN = vec3(0.042, 0.11, 0.175),
         skyColS = vec3(0.2, 0.2, 0.3);
    vec3 grad = getTimeColor(sunAngle.y, vec3(0.4, 0.75, 0.9), vec3(0.1, 0.3, 0.5)),
         sky = mix(mix(skyColD, skyColN, night), skyColS, dusk);
    vec3 al = mix(grad, sky, sDepth.x);

    float sunFactor = mix(0.15, 0.4, sunAngle.y);
    return mix(al, vec3(1), sDepth.y*sunFactor);
}

// (i) Clouds
hp vec3 volumetricBubble(hp vec3 rPos, vec3 albedo, vec3 cColor, vec3 cShadowsCol, float mie){
    if(rPos.y < 0.0) return albedo;
    
	hp vec2 nPos = rPos.xz/rPos.y*getDithering(rPos.xz, 0.05);
	float cDensity = 0.52, shadowsGradation = 0.0,
	      cHorizon = smoothstep(0.0, 0.1+(rain*0.15), rPos.y),
	      cCoverage = smoothstep(0.0, 0.8, noise2D(tm*0.001+nPos*0.05+1.0));
	cDensity *= cCoverage;
	for(int i = 0; i < 12; i++) {
	    cColor *= 1.0+(mie*0.2);
	    albedo = mix(albedo, cColor, saturate(fbmA(nPos, cDensity))*cHorizon);
	  	shadowsGradation += 0.02; cColor = mix(cColor, cShadowsCol, shadowsGradation);
	  	nPos *= 0.94; mie *= 0.8; if(i > 6) cDensity *= 0.87; else cDensity *= 1.065;
	}
	return albedo;
}
hp float getBlockyThingy(hp vec3 np, int u) {
    float blockyNoise = 0.0;
    hp vec3 cp = np/np.y, cTime = vec3(tm, 0, tm)*0.05;
    cp *= getDithering(np.xz, 0.05);
    for(int i = 0; i < 5; i++) {
        blockyNoise += step(0.8-(rain*0.7), random3D(floor(cp+cTime)));
        cp.xz *= 0.96;
    }
    return smoothstep(0.0, float(u), blockyNoise);
}
hp vec3 rayMarchedBlockyThingy(hp vec3 np, vec3 al, vec3 cCol, vec3 sCol) {
    float rBase = getBlockyThingy(np, 1);
    if (rBase > 0.0) {
        vec3 rDir = normalize(lightAngle-np)*0.02, rPos = np+rDir;
        float rHeight = getBlockyThingy(rPos, 7);
        float rInside = max0(rHeight-(rPos.y-np.y));
        cCol = mix(cCol, sCol, rInside);
    }
    return mix(al, cCol, rBase*smoothstep(0.0, 0.25, np.y));
}

// (i) Combination
vec3 getAestheticSky(hp vec3 np, int o) {
    hp vec2 fp = np.xz/np.y;
    float upperSky = getUpperSky(np.y),
          halfSky  = smoothstep(0.0, 0.5, np.y);
    vec3 albedo = getSkyColor(np);
    
    #ifdef enableStars
        float stars = getStars(np); 
        #ifdef enableStarsShooting
            if(bool(o))
                stars += getShootingStars(fp*vec2(15.0, 0.3))*smoothstep(0.0, 0.3, np.y);
        #endif
        stars *= halfSky; albedo += stars*min1(night+dusk*0.3)*(1.0-rain);
    #endif
    #ifdef enableAurora
        if(halfSky > 0.0 && night > 0.0)
            albedo = auroraBorealis(fp*0.3, albedo, night*halfSky);
    #endif
    
    vec3 sunAndMoon = getSM(np, 1)*4.0*getTimeColor(sunAngle.y, vec3(1), vec3(0));
    sunAndMoon += getSM(np, 0)*mix(1.0, 0.1, max0(sunAngle.y))*vec3(0.4, 0.8, 1.1);
    float sMie = simpleMiePhase0(np, 1, 0.5, 1.0),
          mMie = simpleMiePhase0(np, 0, 0.7, 1.2);
    float allMie = mix(sMie, mMie, night);
    #ifndef terrainShader
        albedo += sunAndMoon*upperSky;
    #endif
    vec3 cCol = getTimeColor(sunAngle.y),
         sCol = getSkyColor(vec3(0, 0.6, 0));
    sCol *= mix(clamp(sunAngle.y, 0.4, 0.7), 1.0, night);
    
    #ifdef enableClouds
        #if cloudsMode == 1
            cCol = cCol*(1.0+allMie);
            sCol = mix(sCol, cCol, allMie*0.2);
            albedo = rayMarchedBlockyThingy(np, albedo, cCol, sCol*1.5);
        #elif cloudsMode == 0
            sCol = saturationAdjuster(sCol*0.7, 3.0);
            albedo = volumetricBubble(np, albedo, cCol, sCol, allMie);
        #endif
    #endif
    albedo = rainSaturation(albedo, 1.0);
    return albedo;
}

vec3 theEndSky(hp vec3 np, hp vec3 rp, int o) {
    float fogLevel = smoothstep(0.0, 0.5, np.y);

    vec3 skyColor = vec3(0.17, 0.11, 0.17);
    skyColor *= 1.0+(1.0-fogLevel);
    
    vec3 endLight = normalize(vec3(0.5, 0.8, 0.5));
    float lightDot = smoothstep(0.0, 2.5, dot(np, endLight));
    lightDot *= 1.5;
    
    if(bool(o))
        lightDot = max(lightDot, getStars(np)*fogLevel);
    
    vec3 lightCol = vec3(1.155, 0.93, 1.155);
    skyColor = mix(skyColor, lightCol, lightDot);
    
    float softClouds = smoother(fbm(rp.xz*0.5, 0.6, 0.5));
    softClouds *= fogLevel*0.5;
    
    vec3 cCol = vec3(0.42, 0.28, 0.42);
    cCol = mix(cCol, lightCol, lightDot);
    skyColor = mix(skyColor, cCol, softClouds);
    return skyColor;
}


































// Name : EVBE's function file v0.8r
// Notice : Some of code has been taken from the internet..
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved to their respective owners.