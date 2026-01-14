// [!] You should not make a change here if you have no idea to edit this properly.
vec3 fastApproximateAA(sampler2D texture0, vec2 resolution, vec2 ScreenPos, vec2 texcoord, vec3 outColor) {
    vec2 perScreenPixels = vec2(1.0) / (resolution * (ScreenPos.xy / 64.0 * 0.25 + 0.75));
    vec2 perPixelsOffset = vec2(-1.0, 1.0) * perScreenPixels;
    vec2 perPixelsPosition = texcoord;

    vec3 pixels[5];
    pixels[0] = texture2D(texture0, perPixelsPosition).rgb;
    pixels[1] = texture2D(texture0, perPixelsPosition + perPixelsOffset.xx).rgb;
    pixels[2] = texture2D(texture0, perPixelsPosition + perPixelsOffset.yx).rgb;
    pixels[3] = texture2D(texture0, perPixelsPosition + perPixelsOffset.xy).rgb;
    pixels[4] = texture2D(texture0, perPixelsPosition + perPixelsOffset.yy).rgb;

    float grayscalePixels[5];
    grayscalePixels[0] = luminance(pixels[0]);
    grayscalePixels[1] = luminance(pixels[1]);
    grayscalePixels[2] = luminance(pixels[2]);
    grayscalePixels[3] = luminance(pixels[3]);
    grayscalePixels[4] = luminance(pixels[4]);

    float minGrayscale = min(min(min(min(grayscalePixels[0], grayscalePixels[1]), grayscalePixels[2]), grayscalePixels[3]), grayscalePixels[4]);
    float maxGrayscale = max(max(max(max(grayscalePixels[0], grayscalePixels[1]), grayscalePixels[2]), grayscalePixels[3]), grayscalePixels[4]);

    vec2 blendingDirection = vec2(grayscalePixels[1] + grayscalePixels[2] - grayscalePixels[3] - grayscalePixels[4],
                                  grayscalePixels[1] + grayscalePixels[3] - grayscalePixels[2] - grayscalePixels[4]);
    blendingDirection *= vec2(-1.0, 1.0);
    float grayscalePixelsSum = grayscalePixels[1] + grayscalePixels[2] + grayscalePixels[3] + grayscalePixels[4];
    float blendingPerPixels = max(grayscalePixelsSum / 32.0, 1.0 / 128.0);
    float pixelsBlendingDirection = 1.0 / (min(abs(blendingDirection.x), abs(blendingDirection.y)) + blendingPerPixels);

    blendingDirection = min(vec2(8.0), max(vec2(-8.0), blendingDirection * pixelsBlendingDirection)) * perScreenPixels;

    vec3 outsideBlending = (pixels[1] + pixels[2]) * 0.5;
    vec3 insideBlending = (pixels[0] + pixels[3] + pixels[4]) * 0.25 + outsideBlending * 0.5;

    float grayscaleBlend = luminance(insideBlending);

    vec3 outputColor = (grayscaleBlend < minGrayscale || grayscaleBlend > maxGrayscale) ? outsideBlending : insideBlending;
    return outColor;
}


































// Name : EVBE's Fast-Approximate Anti-Aliasing file v0.8r
// Notice : Some of code has been taken from the internet.
// Date : 3/6/2023
// (c) 2023, All rights reserved to their respective owners.
