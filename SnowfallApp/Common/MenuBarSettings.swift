import SwiftUI

struct MenuBarSettings: View {
    @State var speed: ClosedRange<Float> = Settings.snowflakeSpeedRange
    @State var size: ClosedRange<Float> = Settings.snowflakeSizeRange
    @State var maxSnowflakes: Float = Float(Settings.maxSnowflakes)
    @State var windowInteraction: Bool = Settings.windowInteraction
    @State var windStrength: Float = Settings.windStrength * 1000

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
                Button("Close app") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Reset", role: .destructive) {
                    Settings.reset()
                    speed = Settings.snowflakeSpeedRange
                    size = Settings.snowflakeSizeRange
                    maxSnowflakes = Float(Settings.maxSnowflakes)
                    windowInteraction = Settings.windowInteraction
                    windStrength = Settings.windStrength * 1000
                }
            }
        }
        .frame(maxWidth: 250)
        .padding()
        .onChange(of: speed) { _, newValue in
            Settings.snowflakeSpeedRange = newValue
        }
        .onChange(of: size) { _, newValue in
            Settings.snowflakeSizeRange = newValue
        }
        .onChange(of: maxSnowflakes) { _, newValue in
            Settings.maxSnowflakes = Int(newValue)
        }
        .onChange(of: windowInteraction) { _, newValue in
            Settings.windowInteraction = newValue
        }
        .onChange(of: windStrength) { _, newValue in
            Settings.windStrength = newValue / 1000
        }
    }
}

#Preview {
    MenuBarSettings()
        .scaledToFit()
}
