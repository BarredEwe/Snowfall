import Cocoa

struct Settings {
    static var snowflakeSizeRange: ClosedRange<Float> = 4...10
    static var maxSnowflakes = 1000
    static var snowflakeSpeedRange: ClosedRange<Float> = 1...3
    static var windStrength: Float = 0.5
}
