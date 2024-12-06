import SwiftUI

@main
struct SnowfallAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SnowFallMetalView()
        }

        MenuBarExtra("Makefile", systemImage: "snowflake.circle") {
            MenuBarSettings()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }

        configure(window)
    }

    private func configure(_ window: NSWindow) {
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
}
