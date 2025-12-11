import SwiftUI

struct MenuBarSettings: View {
    @State private var selectedPreset: SnowPreset = Settings.shared.currentPreset
    @State private var minSpeed: Float = Settings.shared.snowflakeSpeedRange.lowerBound
    @State private var maxSpeed: Float = Settings.shared.snowflakeSpeedRange.upperBound
    @State private var minSize: Float = Settings.shared.snowflakeSizeRange.lowerBound
    @State private var maxSize: Float = Settings.shared.snowflakeSizeRange.upperBound
    @State private var maxSnowflakes: Float = Float(Settings.shared.maxSnowflakes)
    @State private var windowInteraction: Bool = Settings.shared.windowInteraction
    @State private var windStrength: Float = Settings.shared.windStrength * 100

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // --- PRESETS ---
            HStack {
                Text("Режим:")
                    .fontWeight(.medium)
                Spacer()
                Picker("", selection: $selectedPreset) {
                    ForEach(SnowPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
                .onChange(of: selectedPreset) { _, newPreset in
                    if newPreset != .custom {
                        applyPreset(newPreset)
                    } else {
                        Settings.shared.currentPreset = .custom
                        Settings.shared.save()
                    }
                }
            }

            Divider()

            // --- SPEED ---
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Скорость")
                    Spacer()
                    Text(String(format: "%.1f - %.1f", minSpeed, maxSpeed))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Min").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $minSpeed, in: 0.1...8.0) { _ in
                        switchToCustom()
                    }
                }

                HStack {
                    Text("Max").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $maxSpeed, in: 0.1...8.0) { _ in
                        switchToCustom()
                    }
                }
            }

            // --- SIZE ---
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Размер")
                    Spacer()
                    Text(String(format: "%.0f - %.0f", minSize, maxSize))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Min").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $minSize, in: 1...25) { _ in
                        switchToCustom()
                    }
                }

                HStack {
                    Text("Max").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $maxSize, in: 1...25) { _ in
                        switchToCustom()
                    }
                }
            }

            // --- COUNT ---
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Количество")
                    Spacer()
                    Text("\(Int(maxSnowflakes))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Slider(value: $maxSnowflakes, in: 100...10000) { _ in
                    switchToCustom()
                }
            }

            // --- WIND ---
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Сила ветра")
                    Spacer()
                    Text("\(Int(windStrength))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Slider(value: $windStrength, in: 0...500) { _ in
                    switchToCustom()
                }
            }

            Divider()

            Toggle("Взаимодействие с окнами", isOn: $windowInteraction)

            HStack {
                Button("Сбросить") {
                    applyPreset(.comfort)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)

                Spacer()

                Button("Выход") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(width: 300)
        .onChange(of: minSpeed) { _, _ in updateSettings() }
        .onChange(of: maxSpeed) { _, _ in updateSettings() }
        .onChange(of: minSize) { _, _ in updateSettings() }
        .onChange(of: maxSize) { _, _ in updateSettings() }
        .onChange(of: maxSnowflakes) { _, _ in updateSettings() }
        .onChange(of: windStrength) { _, _ in updateSettings() }
        .onChange(of: windowInteraction) { _, val in
            Settings.shared.windowInteraction = val
            Settings.shared.save()
        }
        .onAppear {
            loadValues()
        }
    }

    // MARK: - Helpers

    private func switchToCustom() {
        guard selectedPreset != .custom else { return }
        selectedPreset = .custom
        Settings.shared.currentPreset = .custom
        Settings.shared.save()
    }

    private func applyPreset(_ preset: SnowPreset) {
        Settings.shared.applyPreset(preset)
        loadValues()
    }

    private func updateSettings() {
        if minSpeed > maxSpeed { maxSpeed = minSpeed }
        if minSize > maxSize { maxSize = minSize }

        Settings.shared.snowflakeSpeedRange = minSpeed...maxSpeed
        Settings.shared.snowflakeSizeRange = minSize...maxSize
        Settings.shared.maxSnowflakes = Int(maxSnowflakes)
        Settings.shared.windStrength = windStrength / 100
        Settings.shared.save()
    }

    private func loadValues() {
        let s = Settings.shared
        selectedPreset = s.currentPreset
        minSpeed = s.snowflakeSpeedRange.lowerBound
        maxSpeed = s.snowflakeSpeedRange.upperBound
        minSize = s.snowflakeSizeRange.lowerBound
        maxSize = s.snowflakeSizeRange.upperBound
        maxSnowflakes = Float(s.maxSnowflakes)
        windowInteraction = s.windowInteraction
        windStrength = s.windStrength * 100
    }
}
