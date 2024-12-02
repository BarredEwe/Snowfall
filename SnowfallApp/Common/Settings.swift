import Cocoa

struct Settings {
    static let screenSize = NSScreen.main?.frame.size ?? .zero
    static let snowflakeSizeRange: ClosedRange<CGFloat> = 2...10
    static let maxSnowflakes = Int((screenSize.height * screenSize.width) * 0.0001)
    static let snowflakeSpeedRange: ClosedRange<CGFloat> = 1...5
    static let windStrength: CGFloat = 0.5
}
