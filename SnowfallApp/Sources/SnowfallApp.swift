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
import MetalKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var snowWindows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupSnowWindows()
        NotificationCenter.default.addObserver(self, selector: #selector(setupSnowWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
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
        
        let metalController = MetalSnowViewController(screenRect: screenRect, globalRect: globalRect)
        window.contentViewController = metalController
        
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient, .stationary]
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.setFrame(screenRect, display: true)
        
        window.orderFront(nil)
        
        snowWindows.append(window)
    }
}
