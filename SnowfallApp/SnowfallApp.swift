import SwiftUI

@main
struct SnowfallAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Settings.load()
    }

    var body: some Scene {
        WindowGroup {
            SnowFallMetalView()
        }

        MenuBarExtra("Makefile", systemImage: "snowflake") {
            MenuBarSettings()
        }
        .menuBarExtraStyle(.window)
    }
}

import CoreGraphics

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
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient, .stationary]
        window.makeKeyAndOrderFront(nil)
        window.ignoresMouseEvents = true
    }
}
