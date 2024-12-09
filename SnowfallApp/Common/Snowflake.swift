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

        position = simd_float2(Float.random(in: -(200 * Settings.windStrength)...screenSize.x), Float.random(in: 0...screenSize.y))
    }

    mutating func clear(for screenSize: simd_float2) {
        velocity = .velocity
        size = .size
        color = .color(for: size)

        position.y = -size
        position.x = Float.random(in: -(200 * Settings.windStrength)...screenSize.x)
    }
}

// MARK: Extensions

extension simd_float2 {
    static var velocity: simd_float2 {
        simd_float2(Float.random(in: -1...1), Float.random(in: Settings.snowflakeSpeedRange))
    }
}

extension Float {
    static var size: Float {
        Float.random(in: Settings.snowflakeSizeRange)
    }
}

extension simd_float4 {
    static func color(for size: Float) -> simd_float4 {
        let normalizedSize = (size - Settings.snowflakeSizeRange.lowerBound) / (Settings.snowflakeSizeRange.upperBound - Settings.snowflakeSizeRange.lowerBound)
        let opacity = Swift.max(0.1, 1.0 - normalizedSize * 0.8)
        return simd_float4(1.0, 1.0, 1.0, opacity)
    }
}
