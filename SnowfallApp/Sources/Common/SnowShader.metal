#include <metal_stdlib>
using namespace metal;

struct Snowflake {
    float2 position;
    float2 velocity;
    float4 color;
    float size;
};

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

struct Uniforms {
    float2 screenSize;
    float2 mousePosition;
    float4 windowRect;
    float time;
    float deltaTime;
    float windStrength;
    float minSize;
    float maxSize;
    float minSpeed;
    float maxSpeed;
    bool isWindowInteractionEnabled;
    float particleCount;
    float renderScale;
};

float2 convert_to_metal_coordinates(float2 point, float2 viewSize) {
    float2 inverseViewSize = 1.0 / viewSize;
    return float2((2.0f * point.x * inverseViewSize.x) - 1.0f, (2.0f * -point.y * inverseViewSize.y) + 1.0f);
}

vertex VertexOut vertex_main(const device Snowflake *snowflakes [[buffer(0)]],
                              constant Uniforms &uniforms [[buffer(1)]],
                              uint vertexID [[vertex_id]]) {
    VertexOut out;
    float2 pos = convert_to_metal_coordinates(snowflakes[vertexID].position, uniforms.screenSize);
    out.position = float4(pos, 0, 1);
    out.pointSize = snowflakes[vertexID].size * uniforms.renderScale;
    out.color = snowflakes[vertexID].color;
    return out;
}

fragment float4 fragment_main(VertexOut fragData [[stage_in]],
                               float2 pointCoord [[point_coord]]) {
    float dist = length(pointCoord - 0.5);
    float delta = fwidth(dist);
    float alpha = 1.0 - smoothstep(0.45 - delta, 0.45 + delta, dist);
    if (alpha < 0.01) discard_fragment();

    float finalAlpha = fragData.color.a * alpha;
    return float4(fragData.color.rgb * finalAlpha, finalAlpha);
}
