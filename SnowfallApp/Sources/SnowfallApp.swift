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
        NSApp.setActivationPolicy(.accessory)
        setupSnowWindows()
        NotificationCenter.default.addObserver(self, selector: #selector(setupSnowWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleSpaceChange), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleSpaceChange), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        updateSnowVisibility()
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
        
        updateSnowVisibility()
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
        window.collectionBehavior = [.ignoresCycle, .transient, .stationary]
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.setFrame(screenRect, display: true)
        
        window.orderFront(nil)
        
        snowWindows.append(window)
    }
    
    @objc private func handleSpaceChange() {
        updateSnowVisibility()
    }
    
    private func updateSnowVisibility() {
        let shouldHide = isAnyFullscreenWindowPresent()
        for window in snowWindows {
            if shouldHide {
                window.orderOut(nil)
            } else {
                window.orderFront(nil)
            }
        }
    }
    
    private func isAnyFullscreenWindowPresent() -> Bool {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return false }
        
        let screenSizes = NSScreen.screens.map { $0.frame.size }
        let tolerance: CGFloat = 2.0
        
        for entry in windowList {
            guard let layer = entry[kCGWindowLayer as String] as? Int, layer == 0,
                  let bounds = entry[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat else { continue }
            
            for screenSize in screenSizes {
                let widthClose = abs(width - screenSize.width) <= tolerance
                let heightClose = abs(height - screenSize.height) <= tolerance
                if widthClose && heightClose {
                    return true
                }
            }
        }
        return false
    }
}
