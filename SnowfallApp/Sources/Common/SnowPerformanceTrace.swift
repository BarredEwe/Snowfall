#if SNOWFALL_PROFILING
import Foundation
import Metal
import QuartzCore

/// Compiled only into profiling builds; GPU times exclude WindowServer compositing.
final class SnowPerformanceTrace {
    private let lock = NSLock()
    private var start = CACurrentMediaTime()
    private var frames = 0
    private var gpuSeconds = 0.0

    func record(_ buffer: MTLCommandBuffer, device: MTLDevice, drawableSize: CGSize, particles: Int) {
        lock.lock()
        defer { lock.unlock() }
        precondition(buffer.status == .completed, "Metal command failed: \(String(describing: buffer.error))")
        frames += 1
        gpuSeconds += buffer.gpuEndTime - buffer.gpuStartTime
        let now = CACurrentMediaTime()
        let elapsed = now - start
        guard elapsed >= 5 else { return }
        let row: [String: Double] = [
            "fps": Double(frames) / elapsed,
            "gpu_ms_per_frame": gpuSeconds * 1000 / Double(frames),
            "gpu_ms_per_second": gpuSeconds * 1000 / elapsed,
            "metal_allocated_mib": Double(device.currentAllocatedSize) / 1_048_576,
            "drawable_width": drawableSize.width,
            "drawable_height": drawableSize.height,
            "particles": Double(particles)
        ]
        let data = try! JSONSerialization.data(withJSONObject: row, options: [.sortedKeys])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data([10]))
        frames = 0
        gpuSeconds = 0
        start = now
    }
}
#endif
