// [!] You should not make a change here if you have no idea to edit this properly.
// (i) Random
hp float random1D(hp float x) {
    return fract(sin(x)*43758.5453);
}
hp float random2D(hp vec2 x) {
    return fract(sin(dot(x, vec2(12.9898, 78.233)))*43758.5453);
}
hp float random3D(hp vec3 x) {
    return fract(sin(dot(x, vec3(12.9898, 78.233, 45.164)))*43758.5453);
}

// (i) Perlin
/*hp float noise1D(hp float x) {
    hp float p = floor(x),
    f = fract(x); f = f*f*(3.0-2.0*f);
    hp float n = p*57.0;
    return mix(random1D(n), random1D(n+1.0), f.x);
}*/
hp float noise2D(hp vec2 x) {
    hp vec2 p = floor(x),
    f = fract(x); f = f*f*(3.0-2.0*f);
    hp float n = p.x+p.y*57.0;
    return mix(mix(random1D(n), random1D(n+1.0), f.x), 
	           mix(random1D(n+57.0), random1D(n+58.0), f.x), f.y);
}
/*hp float noise3D(hp vec3 x) {
    hp vec3 p = floor(x),
    f = fract(x); f = f*f*(3.0-2.0*f);
    hp float n = p.x+p.y*57.0+p.z*113.0;
    return mix(mix(mix(random1D(n), random1D(n+1.0), f.x),
                   mix(random1D(n+57.0), random1D(n+58.0), f.x), f.y),
               mix(mix(random1D(n+113.0), random1D(n+114.0), f.x),
                   mix(random1D(n+170.0), random1D(n+171.0), f.x), f.y), f.z);
}*/

// (i) fBM
hp float fbm(hp vec2 nPos, float d, float s) {
    float fbmNoise = 0.0, t = tm*s;
    for(int i = 0; i < 4; i++) {
    	  fbmNoise += d*noise2D(nPos);
    	  d *= 0.5, nPos *= 2.5;
    	  nPos -= float(i)+t;
    }
    return saturate(fbmNoise);
}
hp float fbmA(hp vec2 nPos, float d) {
    float noise = fbm(nPos, d, 0.1);
    return smoothstep(0.7-(rain*0.5), 1.0, noise);
}

// (i) Worley
hp float wnoise(hp vec2 x) {
    hp vec2 i = floor(x), f = fract(x);
    float a = 1.0;
    for(int x = -1; x <= 1; x++)
    for(int y = -1; y <= 1; y++) {
        float d = distance(random2D(i+vec2(x, y))+vec2(x, y), f);
        a = min(a, d);
    }
    return a;
}

// (i) Triangular
const mat2 tRot = mat2(-0.95534, -0.29552, 0.29552, -0.95534);
hp float getTriangle(hp float x) {
	  float tBase = fract(x)-0.5;
	  return clamp(abs(tBase), 0.01, 0.49);
}
hp vec2 getTriangle(hp vec2 x) {
	  hp float t0 = getTriangle(x.x), t1 = getTriangle(x.y),
	           t2 = getTriangle(x.y+t0);
	  return vec2(t0-t1, t2);
}
hp float triNoise2d(hp vec2 x, float spd) {
    float scale0 = 1.8, scale1 = 0.4;
    hp float tNoise = 0.0;
    mat2 rotate0 = rot(x.x*0.1),
         rotate1 = rot(tm*spd);
    x *= rotate0; vec2 bp = x;

    const int steps = 3;
    const float bpM = 1.5, scale1M = 2.22, scale0M = 0.42;
    for(int i = 0; i < steps; i++) {
    	  hp vec2 tBase = getTriangle(bp*1.85)*0.75;
    	  tBase *= rotate1; x -= tBase*scale1;

    	  bp *= bpM, scale1 *= scale1M, scale0 *= scale0M;
    	  x *= 1.21+(tNoise-1.0)*0.02;

    	  tNoise += getTriangle(x.x+(getTriangle(x.y)))*scale0;
    	  x *= tRot;
    }
    tNoise *= 30.0;
    return clamp(1.0/tNoise, 0.0, 0.55);
}

// (i) Dithering shortcut
hp float getDithering(hp vec2 np, float scale) {
    return mix(1.0, random2D(floor(np*4096.0)), scale);
}
hp float getDithering(hp vec3 np, float scale) {
    return mix(1.0, random3D(floor(np*4096.0)), scale);
}

































// Name : EVBE's noise file v0.8r
// Notice : Some of code has been taken from the internet.
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved to their respective owners.