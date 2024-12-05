import SwiftUI
import simd

struct Snowflake {
    var position: simd_float2
    var velocity: simd_float2
    var color: simd_float4
    var size: Float

    init(for screenSize: simd_float2) {
        velocity = .velocity
        size = .size
        color = .color(for: size)

        position = simd_float2(Float.random(in: 0...screenSize.x), Float.random(in: 0...screenSize.y))
    }

    mutating func clear(for screenSize: simd_float2) {
        velocity = .velocity
        size = .size
        color = .color(for: size)

        position.y = -size
        position.x = Float.random(in: 0...screenSize.x)
    }
}
