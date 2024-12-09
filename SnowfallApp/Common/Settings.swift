import Cocoa
import SwiftUI

struct Settings {
    @AppStorage("snowflakeSizeRange")
    static var snowflakeSizeRange: ClosedRange<Float> = 3...13
    @AppStorage("maxSnowflakes")
    static var maxSnowflakes = 1000
    @AppStorage("snowflakeSpeedRange")
    static var snowflakeSpeedRange: ClosedRange<Float> = 1...3
    @AppStorage("windStrength")
    static var windStrength: Float = 2.5
    @AppStorage("semltingSpeed")
    static var semltingSpeed: Float = 0.05
    @AppStorage("windowInteraction")
    static var windowInteraction: Bool = true

    static func reset() {
        UserDefaults.standard.dictionaryRepresentation().keys.forEach({ UserDefaults.standard.removeObject(forKey: $0) })
    }
}

// MARK: - Extensions

extension Float: @retroactive RawRepresentable {
    public var rawValue: String {
        String(self)
    }
    
    public typealias RawValue = String

    public init?(rawValue: String) {
        self = Float(rawValue)!
    }
}

extension ClosedRange: @retroactive RawRepresentable where Bound == Float {
    public init?(rawValue: String) {
        let split = rawValue.split(separator: "...")

        self.init(uncheckedBounds: (lower: Float(split[0])!, upper: Float(split[1])!))
    }
    
    public var rawValue: String {
        return String(lowerBound) + "..." + String(upperBound)
    }
}
