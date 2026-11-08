import Cocoa
import CoreGraphics
import QuartzCore

class WindowInfo {
    static let shared = WindowInfo()
    private let statusBarSize = 38.0
    private let lauchpadLayer = 27
    private var lastCheckTime: CFTimeInterval = -.infinity
    private var cachedRect: CGRect?

    func getActiveWindowRect() -> CGRect? {
        let now = CACurrentMediaTime()
        if now - lastCheckTime < 0.5 { return cachedRect }
        lastCheckTime = now
        cachedRect = queryActiveWindowRect()
        return cachedRect
    }

    private func queryActiveWindowRect() -> CGRect? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return nil }

        guard !isLaunchpadVisible(in: windowListInfo) else { return nil }

        for windowInfo in windowListInfo {
            guard let layer = windowInfo[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let windowBounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                  let x = windowBounds["X"] as? CGFloat,
                  let y = windowBounds["Y"] as? CGFloat,
                  let width = windowBounds["Width"] as? CGFloat else { continue }

            if !(x == 0 && (y == statusBarSize || y == 0)) && width >= 50 {
                return CGRect(x: x, y: y, width: width, height: 50.0)
            } else {
                return nil
            }
        }
        return nil
    }

    private func isLaunchpadVisible(in windowList: [[String: Any]]) -> Bool {
        for window in windowList {
            if let ownerName = window["kCGWindowOwnerName"] as? String, ownerName == "Dock",
               let layer = window["kCGWindowLayer"] as? Int {
                if layer == lauchpadLayer {
                    return true
                }
            }
        }
        return false
    }
    
    func cast(from global: CGRect, to local: CGRect, point: CGPoint) -> CGPoint {
        let x = point.x - local.origin.x
        let y = point.y - (global.height - (local.origin.y + local.height))
        return CGPoint(x: x, y: y)
    }
}
