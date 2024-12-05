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

vertex VertexOut vertex_main(const device Snowflake *snowflakes [[buffer(0)]],
                             constant float2 &screenSize[[buffer(1)]],
                             uint vertexID [[vertex_id]]) {
    VertexOut out;

    float2 position = snowflakes[vertexID].position;
    float size = snowflakes[vertexID].size;
    float4 color = snowflakes[vertexID].color;

    out.position = float4(position.x / screenSize.x * 2.0 - 1.0,
                          (1.0 - position.y / screenSize.y) * 2.0 - 1.0,
                          0.0,
                          1.0);
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
