import Foundation

enum SnowRenderPolicy {
    // Soft particles do not need a full Retina-resolution desktop surface.
    static let maximumDrawablePixels = 2_073_600.0

    static func drawableSize(for bounds: CGSize) -> CGSize {
        let scale = min(1, sqrt(maximumDrawablePixels / (bounds.width * bounds.height)))
        return CGSize(width: max(1, floor(bounds.width * scale)),
                      height: max(1, floor(bounds.height * scale)))
    }

    static func framesPerSecond(lowPower: Bool, thermalState: ProcessInfo.ThermalState) -> Int {
        lowPower || thermalState == .serious || thermalState == .critical ? 20 : 30
    }
}
