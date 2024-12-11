import Cocoa
import CoreGraphics

class WindowInfo {
    let statusBarSize = 38.0

    func getActiveWindowRect() -> CGRect? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []

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
}
