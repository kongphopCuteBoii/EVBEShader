#include "fragmentVersionCentroid.h"
#include "uniformShaderConstants.h"
#include "util.h"

#define endShader
#include "libs/! config.glsl"
#include "libs/EVBE_lib.glsl"
#include "libs/EVBE_color.glsl"
#include "libs/EVBE_noise.glsl"
varying hp vec3 wPos;

#include "libs/EVBE_function.glsl"

void main() {
    vec3 np = normalize(vec3(wPos.x, wPos.y+0.128, wPos.z)),
         rp = np/np.y;
    vec3 albedo = theEndSky(np, rp, 1);
	gl_FragColor = vec4(colorMask(albedo), 1);
}