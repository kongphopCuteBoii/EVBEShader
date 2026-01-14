// [!] You should not make any changes here if you have no idea to edit this properly.
// (i) Regular functions
float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}
vec3 tempToRGB(float x) {
    vec3 retColor;
    x = clamp(x, 1000.0, 40000.0)/100.0;
    if (x <= 66.0)
        retColor.rg = vec2(1.0, saturate(0.39008157876901960784*log(x)-0.63184144378862745098));
    else {
        float t = x-60.0;
        retColor.rg = vec2(saturate(1.29293618606274509804*pow(t, -0.1332047592)), saturate(1.12989086089529411765*pow(t, -0.0755148492)));
    }
    if (x >= 66.0)
        retColor.b = 1.0;
    else if (x <= 19.0)
        retColor.b = 0.0;
    else
        retColor.b = saturate(0.54320678911019607843*log(x-10.0)-1.19625408914);
    return saturate(retColor);
}
vec3 saturationAdjuster(vec3 col, float x) {
    vec3 luminancedCol = vec3(luminance(col));
    return mix(luminancedCol, col, x);
}
vec3 rainSaturation(vec3 col, float i) {
    return saturationAdjuster(col, 1.0-(rain*i));
}

/* !! Under the construction !! */
/* |--------------------------|
const mat3 colInput = mat3(0.5972, 0.3546, 0.0482, 0.0760, 0.9083, 0.0157, 0.0284, 0.1338, 0.8378),
           colOutput = mat3(1.6048, -0.5311, -0.0737, -0.1021, 1.1081, -0.0061, -0.0033, -0.0728, 1.0760);
vec3 RRTnODTFit(vec3 x) {
    vec3 a = x*(x+0.0246)-0.0001,
    b = x*(0.9837*x+0.433)+0.2381;
    return a/b;
}
vec3 StephenHillsACES(vec3 x) {
    x = mul(colInput, x);
    x = RRTnODTFit(x);
    x = mul(colOutput, x);
    return x*1.5;
}
   |--------------------------| */
// (i) ACES tonemapper
vec3 NarkowiczACES(vec3 x) {
	float a = 4.6, b = 0.1, 
	c = 3.6, d = 0.48, e = 0.6;
    return ((x*(a*x+b))/(x*(c*x+d)+e));
}

// (i) Color mask (Final shading)
vec3 colorMask(vec3 x) {
    x = NarkowiczACES(x)*tExposure;
    x = pow(x, vec3(tContrast));
    return saturationAdjuster(x, tSaturation);
}




































// Name : EVBE's color file v0.8r
// Notice : Some of code has been taken from the internet.
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved to their respective owners.