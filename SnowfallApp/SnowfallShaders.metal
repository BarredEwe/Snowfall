#include <metal_stdlib>
using namespace metal;

struct Snowflake {
    float2 position; // Позиция снежинки
    float size;      // Размер снежинки
};

kernel void snowflakeVertexShader(const device Snowflake* snowflakes [[ buffer(0) ]],
                                   uint id [[ thread_position_in_grid ]],
                                   device float4* outPosition [[ buffer(1) ]]) {
    if (id < 100) { // Измените 100 на количество снежинок
        float2 pos = snowflakes[id].position;
        outPosition[id] = float4(pos.x, pos.y, 0.0, 1.0);
    }
}

fragment float4 snowflakeFragmentShader(float4 inPosition [[ position ]]) {
    return float4(1.0, 1.0, 1.0, 1.0); // Белый цвет снежинки
}
