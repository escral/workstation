#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec2 resolution;
    vec4 skyTop;
    vec4 skyBottom;
    vec4 c0;
    vec4 c1;
    vec4 c2;
    vec4 c3;
    vec4 c4;
    vec4 c5;
};

const float TAU = 6.2831853;

// Smooth loop through the six palette colors; x in turns of the palette.
vec3 palette(float x) {
    x = fract(x) * 6.0;
    vec3 c[6] = vec3[6](c0.rgb, c1.rgb, c2.rgb, c3.rgb, c4.rgb, c5.rgb);
    int i = int(x);
    return mix(c[i], c[(i + 1) % 6], smoothstep(0.0, 1.0, fract(x)));
}

// 0..1..0 over `period` seconds
float wave(float period, float phase) {
    return 0.5 + 0.5 * sin(TAU * (time / period + phase));
}

vec3 glow(vec3 base, vec2 px, vec2 center, float radius, vec3 tint, float strength) {
    float d = clamp(distance(px, center) / radius, 0.0, 1.0);
    return mix(base, tint, strength * (1.0 - smoothstep(0.0, 1.0, d)));
}

// Interleaved gradient noise. Dark gradients across a whole screen span only
// a few 8-bit steps, which show as rings; ±1/255 of noise hides the steps.
float noise(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

void main() {
    // Texture coords, not gl_FragCoord: their origin is top-left on every
    // graphics backend, matching QML's coordinates.
    vec2 px = qt_TexCoord0 * resolution;
    float big = max(resolution.x, resolution.y);
    vec3 c = mix(skyTop.rgb, skyBottom.rgb, qt_TexCoord0.y);

    // Glows sit in opposite corners and drift; their tints walk the palette
    // half a turn apart, so the two sides never share a hue.
    vec2 a = resolution * vec2(0.15 + 0.25 * wave(97.0, 0.0), 0.10 + 0.30 * wave(71.0, 0.3));
    vec2 b = resolution * vec2(0.85 - 0.25 * wave(83.0, 0.5), 0.90 - 0.30 * wave(109.0, 0.1));
    c = glow(c, px, a, big * 0.45, palette(time / 240.0), 0.22);
    c = glow(c, px, b, big * 0.40, palette(time / 240.0 + 0.5), 0.20);

    c += (noise(gl_FragCoord.xy) - 0.5) * 2.0 / 255.0;
    fragColor = vec4(c, 1.0) * qt_Opacity;
}
