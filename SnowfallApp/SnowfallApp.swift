import SwiftUI

@main
struct SnowfallAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Settings.load()
    }

    var body: some Scene {
        WindowGroup(id: "firstScreen") {
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
        
        guard NSScreen.screens.count > 1 else { return }
        var screens = NSScreen.screens
        screens.removeFirst()
        screens.forEach { screen in
            let controller = NSHostingController(rootView: SnowFallMetalView())
            let inactiveWindow = NSWindow(contentViewController: controller)
            configure(inactiveWindow, inactiveScreen: screen)
        }
    }

    private func configure(_ window: NSWindow, inactiveScreen: NSScreen? = nil) {
        window.isOpaque = true
        window.hasShadow = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.styleMask.remove(.closable)
        window.styleMask.remove(.miniaturizable)
        window.styleMask.remove(.resizable)
        window.styleMask = [.borderless]
        if inactiveScreen == nil {
            window.setFrame(NSScreen.screens.first?.frame ?? .zero, display: true)
        } else {
            window.setFrame(inactiveScreen?.frame ?? .zero, display: true)
        }
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient, .stationary]
        window.makeKeyAndOrderFront(nil)
        window.ignoresMouseEvents = true
    }
}
