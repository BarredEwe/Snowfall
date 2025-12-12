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
    var isWindowInteractionEnabled: Bool
    var _padding: (Bool, Bool, Bool) = (false, false, false)
}

class SnowRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var particleBuffer: MTLBuffer!
    
    private var renderPipelineState: MTLRenderPipelineState!
    private var computePipelineState: MTLComputePipelineState!
    
    private var snowflakes: [Snowflake] = []
    
    var mousePosition: simd_float2 = simd_float2(-1000, -1000)
    var screenSize: simd_float2 = .zero
    
    private var cachedWindowRect: CGRect = .zero
    private var lastWindowCheckTime: TimeInterval = 0
    private let windowCheckInterval: TimeInterval = 0.5
    
    private var lastDrawTime: CFTimeInterval = CACurrentMediaTime()
    
    init(mtkView: MTKView, screenSize: CGSize) {
        super.init()
        self.device = mtkView.device
        self.commandQueue = device.makeCommandQueue()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.layer?.isOpaque = false
        
        createPipelineStates()
        
        self.screenSize = SIMD2(Float(screenSize.width), Float(screenSize.height))
        generateSnowflakes()
    }
    
    private func createPipelineStates() {
        let library = device.makeDefaultLibrary()
        
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
        
        if let computeFunction = library?.makeFunction(name: "updateSnowflakes") {
            do {
                computePipelineState = try device.makeComputePipelineState(function: computeFunction)
            } catch {
                print("Compute Pipeline Error: \(error)")
            }
        }
    }
    
    func generateSnowflakes() {
        let maxSnowflakes = Settings.shared.maxSnowflakes
        snowflakes = (0..<maxSnowflakes).map { _ in Snowflake(for: screenSize) }
        let bufferSize = snowflakes.count * MemoryLayout<Snowflake>.stride
        particleBuffer = device.makeBuffer(bytes: snowflakes, length: bufferSize, options: .storageModeShared)
    }
    
    private func updateActiveWindowRect() {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastWindowCheckTime > windowCheckInterval {
            if Settings.shared.windowInteraction, let rect = WindowInfo().getActiveWindowRect() {
                cachedWindowRect = rect
            } else {
                cachedWindowRect = CGRect(x: -1000, y: -1000, width: 0, height: 0)
            }
            lastWindowCheckTime = currentTime
        }
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let computePipeline = computePipelineState else { return }
        
        if snowflakes.count != Settings.shared.maxSnowflakes { generateSnowflakes() }
        updateActiveWindowRect()
        
        let currentTime = CACurrentMediaTime()
        let deltaTime = Float(currentTime - lastDrawTime)
        lastDrawTime = currentTime
        
        var uniforms = SnowUniforms(
            screenSize: screenSize,
            mousePosition: mousePosition,
            windowRect: simd_float4(Float(cachedWindowRect.origin.x), Float(cachedWindowRect.origin.y), Float(cachedWindowRect.width), Float(cachedWindowRect.height)),
            time: Float(currentTime),
            deltaTime: deltaTime,
            windStrength: Settings.shared.windStrength,
            minSize: Settings.shared.snowflakeSizeRange.lowerBound,
            maxSize: Settings.shared.snowflakeSizeRange.upperBound,
            isWindowInteractionEnabled: Settings.shared.windowInteraction
        )
        
        // Compute
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setBytes(&uniforms, length: MemoryLayout<SnowUniforms>.stride, index: 1)
        
        let width = computePipeline.threadExecutionWidth
        let threadsPerGrid = MTLSize(width: snowflakes.count, height: 1, depth: 1)
        let threadsPerGroup = MTLSize(width: width, height: 1, depth: 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
        
        // Render
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<SnowUniforms>.stride, index: 1)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: snowflakes.count)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.screenSize = SIMD2(Float(size.width), Float(size.height))
    }
}
