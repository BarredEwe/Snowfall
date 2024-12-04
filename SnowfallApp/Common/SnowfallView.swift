import SwiftUI

struct SnowfallView: View {
    @State private var screenSize: CGSize = NSScreen.main?.frame.size ?? .zero
    @State private var snowflakes: [Snowflake] = []
    static var mousePosition: CGPoint = .zero
    static let link = DisplayLink()

    var body: some View {
        ZStack {
            Snowflakes(snowflakes: $snowflakes)
        }
        .background(MouseTrackingView { position in
            SnowfallView.mousePosition = position
        })
        .onChange(of: NSScreen.main?.frame.size ?? .zero, initial: true) { oldValue, newValue in
            guard screenSize != newValue else { return }

            screenSize = newValue
        }
        .onAppear {
            startSnowfall()
        }
        .ignoresSafeArea()
    }

    func startSnowfall() {
        SnowfallView.link?.callback = {
            updateSnowflakes()
        }
        SnowfallView.link?.start()
    }

    func updateSnowflakes() {
        snowflakes.removeAll { $0.y > screenSize.height }

        for i in snowflakes.indices {
            let dx = SnowfallView.mousePosition.x - snowflakes[i].x
            let dy = SnowfallView.mousePosition.y - snowflakes[i].y
            let distance = hypot(dx, dy)

            let influenceRadius = 100 * (1 - snowflakes[i].speed / Settings.snowflakeSpeedRange.upperBound)
            let attractionStrength = 0.5

            if distance < influenceRadius {
                let scale = (influenceRadius - distance) / influenceRadius

                snowflakes[i].x -= dx * scale * attractionStrength
                snowflakes[i].y -= dy * scale * attractionStrength
            }

            snowflakes[i].x += CGFloat.random(in: 0.1...1) * Settings.windStrength
            snowflakes[i].y += snowflakes[i].speed

        }

        if snowflakes.count < Settings.maxSnowflakes {
            snowflakes.append(createSnowflake())
        }
    }

    func createSnowflake() -> Snowflake {
        Snowflake(
            x: CGFloat.random(in: 0...screenSize.width),
            y: -10,
            size: CGFloat.random(in: Settings.snowflakeSizeRange),
            speed: CGFloat.random(in: Settings.snowflakeSpeedRange)
        )
    }
}

struct Snowflakes: View {
    @Binding var snowflakes: [Snowflake]

    var body: some View {
        ForEach(snowflakes) { snowflake in
            Circle()
                .fill(Color.white.opacity(0.2 * (Settings.snowflakeSizeRange.upperBound - snowflake.size)))
                .frame(width: snowflake.size, height: snowflake.size)
                .position(x: snowflake.x, y: snowflake.y)
        }
    }
}
