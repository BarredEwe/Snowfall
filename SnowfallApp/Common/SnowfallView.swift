import SwiftUI

struct SnowfallView: View {
    @State private var snowflakes: [Snowflake] = []
    @State private var mousePosition: CGPoint = .zero

    var body: some View {
        ZStack {
            ForEach(snowflakes) { snowflake in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: snowflake.size, height: snowflake.size)
                    .position(x: snowflake.x, y: snowflake.y)
            }
        }
        .background(MouseTrackingView { position in
            mousePosition = CGPoint(x: position.x, y: position.y)
        })
        .onAppear {
            startSnowfall()
            DispatchQueue.main.async {
                setupWindow()
            }
        }
        .ignoresSafeArea()
    }

    func setupWindow() {
        guard let window = NSApplication.shared.windows.first else { return }

        window.isOpaque = true
        window.hasShadow = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.styleMask.remove(.closable)
        window.styleMask.remove(.miniaturizable)
        window.styleMask.remove(.resizable)
        window.styleMask = [.borderless]
        window.setFrame(NSScreen.main?.frame ?? .zero, display: true)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.makeKeyAndOrderFront(nil)
        window.ignoresMouseEvents = true
    }

    func startSnowfall() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                updateSnowflakes()
            }
        }
    }

    func updateSnowflakes() {
        snowflakes.removeAll { $0.y > Settings.screenSize.height }

        snowflakes = snowflakes.map { snowflake in
            var updatedSnowflake = snowflake

            let dx = mousePosition.x - updatedSnowflake.x
            let dy = mousePosition.y - updatedSnowflake.y
            let distance = hypot(dx, dy)

            let influenceRadius = 100 * (1 - updatedSnowflake.speed / Settings.snowflakeSpeedRange.upperBound)
            let attractionStrength = 0.5

            if distance < influenceRadius {
                let scale = (influenceRadius - distance) / influenceRadius

                updatedSnowflake.x -= dx * scale * attractionStrength
                updatedSnowflake.y -= dy * scale * attractionStrength
            }

            updatedSnowflake.x += CGFloat.random(in: -1...1) * Settings.windStrength

            updatedSnowflake.y += updatedSnowflake.speed
            return updatedSnowflake
        }

        if snowflakes.count < Settings.maxSnowflakes {
            snowflakes.append(createSnowflake())
        }
    }

    func createSnowflake() -> Snowflake {
        Snowflake(
            x: CGFloat.random(in: 0...Settings.screenSize.width),
            y: -10,
            size: CGFloat.random(in: Settings.snowflakeSizeRange),
            speed: CGFloat.random(in: Settings.snowflakeSpeedRange)
        )
    }
}
