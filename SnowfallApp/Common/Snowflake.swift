import SwiftUI
import simd

struct Snowflake {
    var position: simd_float2
    var velocity: simd_float2
    var color: simd_float4
    var size: Float
    
    init(for screenSize: simd_float2) {
        let sizeVal = Float.random(in: Settings.shared.snowflakeSizeRange)
        self.size = sizeVal
        
        self.position = simd_float2(
            Float.random(in: 0...screenSize.x),
            Float.random(in: 0...screenSize.y)
        )
        
        let speed = Float.random(in: Settings.shared.snowflakeSpeedRange)
        self.velocity = simd_float2(0, speed)
        
        let normalizedSize = (sizeVal - Settings.shared.snowflakeSizeRange.lowerBound) / (Settings.shared.snowflakeSizeRange.upperBound - Settings.shared.snowflakeSizeRange.lowerBound)
        let opacity = Swift.max(0.2, 0.5 + normalizedSize * 0.5)
        self.color = simd_float4(1.0, 1.0, 1.0, opacity)
    }
}
