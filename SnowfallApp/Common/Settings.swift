import Cocoa
import SwiftUI

class Settings: Codable {

    static var shared = Settings()

    var snowflakeSizeRange: ClosedRange<Float> = 3...13
    var maxSnowflakes = 1000
    var snowflakeSpeedRange: ClosedRange<Float> = 1...3
    var windStrength: Float = 2.5
    var semltingSpeed: Float = 0.05
    var windowInteraction: Bool = true

    private init() {}

    static func reset() {
        UserDefaults.standard.dictionaryRepresentation().keys.forEach({ UserDefaults.standard.removeObject(forKey: $0) })
        load()
    }

    static func save() {
        if let data = try? JSONEncoder().encode(shared) {
            UserDefaults().set(data, forKey: "settings")
        }
    }

    static func load() {
        let settings = UserDefaults().data(forKey: "settings").flatMap({ try? JSONDecoder().decode(Settings.self, from: $0) })
        shared = settings ?? Settings()

    }
}
