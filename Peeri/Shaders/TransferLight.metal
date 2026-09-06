#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 transferAtmosphere(float2 position, half4 color, float2 size, float time, half4 tint) {
    float2 uv = position / max(size, float2(1.0));
    float drift = sin(time * 0.12) * 0.1;
    float halo = exp(-7.0 * length((uv - float2(0.18 + drift, 0.2)) * float2(0.8, 1.1)));
    float ribbon = exp(-pow((uv.y - 0.18 - sin(uv.x * 4.0 + time * 0.08) * 0.1) * 12.0, 2.0));
    float fade = pow(max(0.0, 1.0 - uv.y), 2.0);
    half3 spectrum = mix(tint.rgb, half3(0.40, 0.30, 0.92), half(uv.x * 0.65));
    half alpha = half((halo * 0.7 + ribbon * 0.12) * fade) * color.a;
    return half4(spectrum * alpha, alpha);
}
