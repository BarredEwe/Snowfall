import SwiftUI

@main
struct SnowfallApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Snowfall", systemImage: "snowflake") {
            MenuBarSettings()
        }
        .menuBarExtraStyle(.window)
    }
}

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var snowWindows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupSnowWindows()
        NotificationCenter.default.addObserver(self, selector: #selector(setupSnowWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        #if SNOWFALL_PROFILING
        if ProcessInfo.processInfo.arguments.contains("--profile-pause") {
            for (delay, name) in [(10.0, NSWorkspace.screensDidSleepNotification),
                                  (30.0, NSWorkspace.screensDidWakeNotification)] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    NSWorkspace.shared.notificationCenter.post(name: name, object: nil)
                    print("PROFILE_LIFECYCLE \(name.rawValue)")
                    fflush(stdout)
                }
            }
        }
        #endif
    }
    
    @objc private func setupSnowWindows() {
        snowWindows.forEach { $0.close() }
        snowWindows.removeAll()
        
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude
        
        for screen in NSScreen.screens {
            let f = screen.frame

            maxX = max(maxX, f.maxX)
            maxY = max(maxY, f.maxY)
        }
        
        let globalRect = CGRect(x: 0, y: 0, width: maxX, height: maxY)
        
        for screen in NSScreen.screens {
            createSnowWindow(for: screen, in: globalRect)
        }
    }
    
    private func createSnowWindow(for screen: NSScreen, in globalRect: CGRect) {
        let screenRect = screen.frame
        
        let window = NSWindow(contentRect: screenRect, styleMask: [.borderless], backing: .buffered, defer: false)
        
        let metalController = MetalSnowViewController(screenRect: screenRect, globalRect: globalRect,
                                                     backingScaleFactor: screen.backingScaleFactor)
        window.contentViewController = metalController
        
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        // AppKit keeps desktop overlays out of other apps' full-screen Spaces.
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary, .ignoresCycle, .stationary]
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.setFrame(screenRect, display: true)
        
        window.orderFront(nil)
        
        snowWindows.append(window)
    }
}
