import SwiftUI

@main
struct SnowfallApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Settings.load()
    }

    var body: some Scene {
        MenuBarExtra("Snowfall", systemImage: "snowflake") {
            MenuBarSettings()
        }
        .menuBarExtraStyle(.window)
    }
}

import Cocoa
import MetalKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var snowWindows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupSnowWindows()
        NotificationCenter.default.addObserver(self, selector: #selector(setupSnowWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    @objc private func setupSnowWindows() {
        snowWindows.forEach { $0.close() }
        snowWindows.removeAll()
        
        for screen in NSScreen.screens {
            createSnowWindow(for: screen)
        }
    }
    
    private func createSnowWindow(for screen: NSScreen) {
        let screenRect = screen.frame
        
        let window = NSWindow(contentRect: screenRect, styleMask: [.borderless], backing: .buffered, defer: false)
        
        let metalController = MetalSnowViewController(screenSize: screenRect.size)
        window.contentViewController = metalController
        
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient, .stationary]
        window.ignoresMouseEvents = true
        window.setFrame(screenRect, display: true)
        
        window.orderFront(nil)
        
        snowWindows.append(window)
    }
}
