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

final class Settings: Codable {
    static let shared = Settings()
    
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
    
    private init() {
        load()
    }
    
    func applyPreset(_ preset: SnowPreset) {
        currentPreset = preset
        preset.apply(to: self)
        save()
    }
    
    func reset() {
        UserDefaults.standard.dictionaryRepresentation().keys.forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        load()
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        
        UserDefaults.standard.set(data, forKey: "settings")
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "settings"),
              let settings = try? JSONDecoder().decode(Settings.self, from: data) else {
            applyPreset(.comfort)
            return
        }

        currentPreset = settings.currentPreset
        isPaused = settings.isPaused
        displayMode = settings.displayMode
        pauseInFullscreen = settings.pauseInFullscreen
        snowflakeSizeRange = settings.snowflakeSizeRange
        maxSnowflakes = settings.maxSnowflakes
        snowflakeSpeedRange = settings.snowflakeSpeedRange
        windStrength = settings.windStrength
        meltingSpeed = settings.meltingSpeed
        windowInteraction = settings.windowInteraction
    }
}

extension SnowPreset {
     func apply(to settings: Settings) {
        switch self {
        case .light:
            settings.maxSnowflakes = 800
            settings.snowflakeSpeedRange = 0.2...1.5
            settings.snowflakeSizeRange = 2...12
            settings.windStrength = 0.5
            
        case .comfort:
            settings.maxSnowflakes = 2000
            settings.snowflakeSpeedRange = 0.5...3.0
            settings.snowflakeSizeRange = 3...15
            settings.windStrength = 1.0
            
        case .blizzard:
            settings.maxSnowflakes = 6000
            settings.snowflakeSpeedRange = 2.0...8.0
            settings.snowflakeSizeRange = 2...20
            settings.windStrength = 4.0
            
        case .custom:
            break
        }
    }
}
