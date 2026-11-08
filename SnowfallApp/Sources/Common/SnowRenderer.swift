import MetalKit
import Foundation
import simd
import QuartzCore

struct SnowUniforms {
    var screenSize: simd_float2
    var mousePosition: simd_float2
    var windowRect: simd_float4
    var time: Float
    var deltaTime: Float
    var windStrength: Float
    var minSize: Float
    var maxSize: Float
    var minSpeed: Float
    var maxSpeed: Float
    var isWindowInteractionEnabled: Bool
    var particleCount: Float
    var renderScale: Float
}

final class SnowRenderer: NSObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var renderPipelineState: MTLRenderPipelineState!
    private var snowflakes: [Snowflake] = []
    private final class FrameSlot {
        var buffer: MTLBuffer?
        let available = DispatchSemaphore(value: 1)
    }
    private let frameSlots = [FrameSlot(), FrameSlot()]
    private var nextFrameSlot = 0
    private var particleCount: Int = 0
    private var globalRect: CGRect!
    private var screenRect: CGRect!
    private var backingScaleFactor: CGFloat = 1
    private var renderScale: Float = 1
    private var appliedSpeedRange: ClosedRange<Float> = Settings.shared.snowflakeSpeedRange
    private var appliedSizeRange: ClosedRange<Float> = Settings.shared.snowflakeSizeRange
    
    var mousePosition: simd_float2 = simd_float2(-1000, -1000)
    var screenSize: simd_float2 = .zero
    
    private var cachedWindowRect: CGRect = .zero
    private var lastWindowCheckTime: TimeInterval = 0
    private let windowCheckInterval: TimeInterval = 0.5
    private var lastDrawTime: CFTimeInterval = CACurrentMediaTime()
    #if SNOWFALL_PROFILING
    private let performanceTrace = SnowPerformanceTrace()
    #endif
    
    init(mtkView: MTKView, screenRect: CGRect, globalRect: CGRect, backingScaleFactor: CGFloat) {
        super.init()
        self.globalRect = globalRect
        self.screenRect = screenRect
        self.backingScaleFactor = backingScaleFactor
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.layer?.isOpaque = false
        
        self.screenSize = SIMD2(Float(screenRect.width * backingScaleFactor),
                               Float(screenRect.height * backingScaleFactor))
        self.renderScale = Float(mtkView.drawableSize.width) / screenSize.x
        generateSnowflakes()
    }

    func resetFrameTime() {
        lastDrawTime = CACurrentMediaTime()
    }

    func restoreGPUResources(in view: MTKView) {
        device = view.device
        commandQueue = device.makeCommandQueue(maxCommandBufferCount: 2)
        renderScale = Float(view.drawableSize.width) / screenSize.x
        autoreleasepool { createPipelineStates() }
        resetFrameTime()
    }

    func releaseGPUResources() {
        for slot in frameSlots { slot.buffer = nil }
        renderPipelineState = nil
        commandQueue = nil
        device = nil
    }
    
    private func createPipelineStates() {
        let library = device.makeDefaultLibrary()
        
        // Render pipeline
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Render Pipeline Error: \(error)")
        }
        
    }
    
    private func generateSnowflakes() {
        let maxSnowflakes = Settings.shared.maxSnowflakes
        particleCount = maxSnowflakes
        
        initializeParticles()
    }
    
    private func initializeParticles() {
        appliedSpeedRange = Settings.shared.snowflakeSpeedRange
        appliedSizeRange = Settings.shared.snowflakeSizeRange
        snowflakes = SnowSimulation.initialize(count: particleCount, uniforms: makeCurrentUniforms())
    }
    
    private func makeCurrentUniforms() -> SnowUniforms {
        let cachedWindowRectLocalOrigin = WindowInfo.shared.cast(from: globalRect, to: screenRect, point: cachedWindowRect.origin)
        return SnowUniforms(
            screenSize: screenSize,
            mousePosition: mousePosition,
            windowRect: simd_float4(
                // cast window origin from global to local
                Float(cachedWindowRectLocalOrigin.x * backingScaleFactor),
                Float(cachedWindowRectLocalOrigin.y * backingScaleFactor),
                Float(cachedWindowRect.width * backingScaleFactor),
                Float(cachedWindowRect.height * backingScaleFactor)
            ),
            time: Float(CACurrentMediaTime()),
            deltaTime: Float(CACurrentMediaTime() - lastDrawTime),
            windStrength: Settings.shared.windStrength,
            minSize: Settings.shared.snowflakeSizeRange.lowerBound,
            maxSize: Settings.shared.snowflakeSizeRange.upperBound,
            minSpeed: Settings.shared.snowflakeSpeedRange.lowerBound,
            maxSpeed: Settings.shared.snowflakeSpeedRange.upperBound,
            isWindowInteractionEnabled: Settings.shared.windowInteraction,
            particleCount: Float(particleCount),
            renderScale: renderScale
        )
    }
    
    private func updateActiveWindowRect() {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastWindowCheckTime > windowCheckInterval {
            if Settings.shared.windowInteraction, let rect = WindowInfo.shared.getActiveWindowRect() {
                cachedWindowRect = rect
            } else {
                cachedWindowRect = CGRect(x: -1000, y: -1000, width: 0, height: 0)
            }
            lastWindowCheckTime = currentTime
        }
    }
}

extension SnowRenderer: MTKViewDelegate {
    internal func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Physics stays in display pixels when the drawable resolution changes.
        self.screenSize = SIMD2(Float(view.bounds.width * backingScaleFactor),
                               Float(view.bounds.height * backingScaleFactor))
        self.renderScale = Float(size.width) / screenSize.x
    }
    
    internal func draw(in view: MTKView) {
        autoreleasepool { drawFrame(in: view) }
    }

    private func drawFrame(in view: MTKView) {
        let slot = frameSlots[nextFrameSlot]
        guard slot.available.wait(timeout: .now()) == .success else { return }
        var submitted = false
        defer { if !submitted { slot.available.signal() } }
        guard let commandQueue, let device,
              let renderPipeline = renderPipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        if particleCount != Settings.shared.maxSnowflakes {
            generateSnowflakes()
        } else if Settings.shared.snowflakeSpeedRange != appliedSpeedRange
            || Settings.shared.snowflakeSizeRange != appliedSizeRange {
            initializeParticles()
        }
        
        updateActiveWindowRect()
        
        let currentTime = CACurrentMediaTime()
        let deltaTime = Float(min(currentTime - lastDrawTime, 0.1))
        lastDrawTime = currentTime
        
        var uniforms = makeCurrentUniforms()
        uniforms.deltaTime = deltaTime
        
        SnowSimulation.update(&snowflakes, uniforms: uniforms)
        let bufferSize = particleCount * MemoryLayout<Snowflake>.stride
        if slot.buffer?.length != bufferSize {
            slot.buffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)
        }
        guard let particleBuffer = slot.buffer else { return }
        snowflakes.withUnsafeBytes { bytes in
            particleBuffer.contents().copyMemory(from: bytes.baseAddress!, byteCount: bufferSize)
        }

        // The CPU owns simulation; the GPU only draws this immutable frame snapshot.
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<SnowUniforms>.stride, index: 1)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler { _ in slot.available.signal() }
        #if SNOWFALL_PROFILING
        let drawableSize = view.drawableSize
        let particles = particleCount
        commandBuffer.addCompletedHandler { [performanceTrace] buffer in
            performanceTrace.record(buffer, device: device, drawableSize: drawableSize, particles: particles)
        }
        #endif
        nextFrameSlot = (nextFrameSlot + 1) % frameSlots.count
        submitted = true
        commandBuffer.commit()
    }
}
