import Cocoa

struct Settings {
    private static let screenSize = NSScreen.main?.frame.size ?? .zero
    static let snowflakeSizeRange: ClosedRange<CGFloat> = 2...10
    static let maxSnowflakes = 1000
    static let snowflakeSpeedRange: ClosedRange<CGFloat> = 1...3
    static let windStrength: CGFloat = 0.3
}


