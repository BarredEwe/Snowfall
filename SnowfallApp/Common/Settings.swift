import Foundation

enum DisplayMode: String, CaseIterable, Codable {
    case allMonitors = "На всех мониторах"
    case mainMonitorOnly = "Только на главном"
}

enum SnowPreset: String, CaseIterable, Codable {
    case light = "Лёгкий снег"
    case comfort = "Комфортный фон"
    case blizzard = "Метель"
    case custom = "Свой"
}

class Settings: Codable {
    static var shared = Settings()
    
    var currentPreset: SnowPreset = .comfort
    var isPaused: Bool = false
    var displayMode: DisplayMode = .allMonitors
    var pauseInFullscreen: Bool = true
    var snowflakeSizeRange: ClosedRange<Float> = 3...10
    var maxSnowflakes = 2000
    var snowflakeSpeedRange: ClosedRange<Float> = 0.5...3.0
    var windStrength: Float = 1.0
    var meltingSpeed: Float = 0.05
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
    
    func applyPreset(_ preset: SnowPreset) {
        self.currentPreset = preset
        preset.apply(to: self)
        Settings.save()
    }
}

extension SnowPreset {
     func apply(to settings: Settings) {
        switch self {
        case .light:
            settings.maxSnowflakes = 800
            settings.snowflakeSpeedRange = 0.2...1.5
            settings.snowflakeSizeRange = 2...6
            settings.windStrength = 0.5
            
        case .comfort:
            settings.maxSnowflakes = 2000
            settings.snowflakeSpeedRange = 0.5...3.0
            settings.snowflakeSizeRange = 3...10
            settings.windStrength = 1.0
            
        case .blizzard:
            settings.maxSnowflakes = 6000
            settings.snowflakeSpeedRange = 2.0...8.0
            settings.snowflakeSizeRange = 2...8
            settings.windStrength = 4.0
            
        case .custom:
            break
        }
    }
}
