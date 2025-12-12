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
    bool isWindowInteractionEnabled;
};


float random(uint seed, float time) {
    return fract(sin(float(seed) * 12.9898 + time) * 43758.5453);
}

kernel void updateSnowflakes(device Snowflake *snowflakes [[buffer(0)]],
                             constant Uniforms &uniforms [[buffer(1)]],
                             uint id [[thread_position_in_grid]]) {
    
    device Snowflake &flake = snowflakes[id];
    float timeFactor = uniforms.deltaTime * 60.0;
    
    bool isOnWindow = false;
    if (uniforms.isWindowInteractionEnabled) {
        if (flake.position.x >= uniforms.windowRect.x &&
            flake.position.x <= uniforms.windowRect.x + uniforms.windowRect.z &&
            flake.position.y >= uniforms.windowRect.y &&
            flake.position.y <= uniforms.windowRect.y + uniforms.windowRect.w) {
            isOnWindow = true;
        }
    }
    
    if (isOnWindow) {
        flake.position += flake.velocity * 0.1 * timeFactor;
        
        float meltSpeed = 0.1 * timeFactor;
        flake.size -= meltSpeed;
        
        if (flake.size <= 0.5) {
            flake.position.y = -10.0;
            float rnd = random(id, uniforms.time);
            float widthSpread = uniforms.screenSize.x + 400.0;
            flake.position.x = (rnd * widthSpread) - 200.0;
            
            float sizeRange = uniforms.maxSize - uniforms.minSize;
            flake.size = uniforms.minSize + random(id + 1, uniforms.time) * sizeRange;
        }
        
    } else {
        flake.position += flake.velocity * timeFactor;
        flake.position.x += (uniforms.windStrength * (flake.size * 0.05)) * timeFactor;
        
        // Мышь
        float2 mouseDir = flake.position - uniforms.mousePosition;
        float influenceRadius = 50.0;
        float dist = length(mouseDir);
        if (dist < influenceRadius) {
            float force = (influenceRadius - dist) / influenceRadius;
            flake.position += normalize(mouseDir) * force * 20.0 * timeFactor;
        }
        
        if (flake.position.y > uniforms.screenSize.y + flake.size) {
            flake.position.y = -flake.size;
            float rnd = random(id, uniforms.time);
            float widthSpread = uniforms.screenSize.x + 400.0;
            flake.position.x = (rnd * widthSpread) - 200.0;
        }
    }
    
    if (flake.position.x > uniforms.screenSize.x + 200.0) {
        flake.position.x = -100.0;
    } else if (flake.position.x < -200.0) {
        flake.position.x = uniforms.screenSize.x + 100.0;
    }
}

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
    out.pointSize = snowflakes[vertexID].size;
    out.color = snowflakes[vertexID].color;
    return out;
}

fragment float4 fragment_main(VertexOut fragData [[stage_in]],
                              float2 pointCoord [[point_coord]]) {
    float dist = length(pointCoord - 0.5);
    float delta = fwidth(dist);
    float alpha = 1.0 - smoothstep(0.45 - delta, 0.45 + delta, dist);
    if (alpha < 0.01) discard_fragment();
    return float4(fragData.color.rgb, fragData.color.a * alpha);
}
