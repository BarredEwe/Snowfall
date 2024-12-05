import SwiftUI

struct MenuBarSettings: View {
    @State var speed: Float = Settings.snowflakeSpeedRange.upperBound
    @State var size: Float = Settings.snowflakeSizeRange.upperBound
    @State var maxSnowflakes: Float = Float(Settings.maxSnowflakes)

    var body: some View {
        VStack(spacing: 2) {
            VStack(alignment: .leading, spacing: 2) {
                Group {
                    Row(title: "Snowflake speed: \(speed)")
                        .foregroundColor(.secondary)
                    Slider(value: $speed, in: 1...20.0)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Group {
                    Row(title: "Snowflake size: \(size)")
                        .foregroundColor(.secondary)
                    Slider(value: $size, in: 4...40.0)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Group {
                    Row(title: "Snowflake count: \(maxSnowflakes)")
                        .foregroundColor(.secondary)
                    Slider(value: $maxSnowflakes, in: 1...4000.0)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: 250)
        .padding(.vertical, 4)
        .onChange(of: speed) { oldValue, newValue in
            Settings.snowflakeSpeedRange = Settings.snowflakeSpeedRange.lowerBound...newValue
        }
        .onChange(of: size) { oldValue, newValue in
            Settings.snowflakeSizeRange = Settings.snowflakeSizeRange.lowerBound...newValue
        }
        .onChange(of: maxSnowflakes) { oldValue, newValue in
            Settings.maxSnowflakes = Int(newValue)
        }
    }
}

struct Row: View {
    let title : String
    var hasCheckmark = false

    var body: some View {
        HStack(spacing: 4) {
            Group {
                if hasCheckmark {
                    Image(systemName: "checkmark")
                } else {
                    Text("")
                }
            }
            .frame(width: 12)
            Text(title)
        }
    }
}
