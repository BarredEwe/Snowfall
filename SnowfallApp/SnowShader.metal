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

float2 convert_to_metal_coordinates(float2 point, float2 viewSize) {
    float2 inverseViewSize = 1 / viewSize;
    return float2((2.0f * point.x * inverseViewSize.x) - 1.0f, (2.0f * -point.y * inverseViewSize.y) + 1.0f);
}

vertex VertexOut vertex_main(const device Snowflake *snowflakes [[buffer(0)]],
                             constant float2 &screenSize[[buffer(1)]],
                             uint vertexID [[vertex_id]]) {
    float2 position = convert_to_metal_coordinates(snowflakes[vertexID].position, screenSize);
    float size = snowflakes[vertexID].size;
    float4 color = snowflakes[vertexID].color;

    VertexOut out;
    out.position = float4(position, 0, 1);
    out.pointSize = size;
    out.color = color;

    return out;
}

fragment float4 fragment_main(VertexOut fragData [[stage_in]],
                              float2 pointCoord  [[point_coord]]) {
    if (length(pointCoord - float2(0.5)) > 0.5) {
        discard_fragment();
    }

    return fragData.color;
}
