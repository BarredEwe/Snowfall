import SwiftUI

struct MenuBarSettings: View {
    @State var speed: ClosedRange<Float> = Settings.shared.snowflakeSpeedRange
    @State var size: ClosedRange<Float> = Settings.shared.snowflakeSizeRange
    @State var maxSnowflakes: Float = Float(Settings.shared.maxSnowflakes)
    @State var windowInteraction: Bool = Settings.shared.windowInteraction
    @State var windStrength: Float = Settings.shared.windStrength * 1000

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                Text("Snowflake speed")
                RangedSliderView(value: $speed, in: 1...20)
                Divider()
            }

            VStack(alignment: .leading) {
                Text("Snowflake size")
                RangedSliderView(value: $size, in: 3...40)
                Divider()
            }

            VStack(alignment: .leading) {
                Text("Snowflake count \(Int(maxSnowflakes))")
                Slider(value: $maxSnowflakes, in: 1...4000)
                Divider()
            }

            VStack(alignment: .leading) {
                Text("Wind strength \(Int(windStrength / 100))")
                Slider(value: $windStrength, in: 1...4000)
                Divider()
            }

            Toggle("Snow interact with window", isOn: $windowInteraction)

            HStack {
                Button("Reset", role: .destructive) {
                    Settings.reset()
                    speed = Settings.shared.snowflakeSpeedRange
                    size = Settings.shared.snowflakeSizeRange
                    maxSnowflakes = Float(Settings.shared.maxSnowflakes)
                    windowInteraction = Settings.shared.windowInteraction
                    windStrength = Settings.shared.windStrength * 1000
                }
                
                Spacer()
                
                Button("Close app") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: 250)
        .padding()
        .onChange(of: speed) { _, newValue in
            Settings.shared.snowflakeSpeedRange = newValue
            Settings.save()
        }
        .onChange(of: size) { _, newValue in
            Settings.shared.snowflakeSizeRange = newValue
            Settings.save()
        }
        .onChange(of: maxSnowflakes) { _, newValue in
            Settings.shared.maxSnowflakes = Int(newValue)
            Settings.save()
        }
        .onChange(of: windowInteraction) { _, newValue in
            Settings.shared.windowInteraction = newValue
            Settings.save()
        }
        .onChange(of: windStrength) { _, newValue in
            Settings.shared.windStrength = newValue / 1000
            Settings.save()
        }
    }
}

#Preview {
    MenuBarSettings()
        .scaledToFit()
}
