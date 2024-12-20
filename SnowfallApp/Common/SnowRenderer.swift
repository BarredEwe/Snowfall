import MetalKit
import Foundation
import simd

class SnowRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var particleBuffer: MTLBuffer!
    private var pipelineState: MTLRenderPipelineState!

    private var snowflakes: [Snowflake] = []

    var mousePosition: simd_float2 = simd_float2(.infinity, .infinity)
    var screenSize: simd_float2 = .zero

    private let influenceRadius: Float = 50.0

    init(mtkView: MTKView, screenSize: CGSize) {
        super.init()
        device = mtkView.device
        commandQueue = device.makeCommandQueue()
        mtkView.colorPixelFormat = .bgra8Unorm
        createPipelineState()
        self.screenSize = SIMD2<Float>(Float(screenSize.width), Float(screenSize.height))
        generateSnowflakes()
    }

    private func createPipelineState() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Snowflake>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.inputPrimitiveTopology = .point

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Error Make Pipeline: \(error.localizedDescription)")
        }
    }

    func generateSnowflakes() {
        let maxPossibleCount = 4000
        snowflakes = (0..<maxPossibleCount).map { _ in Snowflake(for: screenSize) }
        particleBuffer = device.makeBuffer(bytes: snowflakes, length: MemoryLayout<Snowflake>.stride * maxPossibleCount, options: [])

        assert(particleBuffer != nil, "Failed to create particle buffer")
    }

    func updateMousePosition(to position: SIMD2<Float>) {
        mousePosition = position
    }

    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        updateSnowflakes()

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)

        // Snowflakes
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)

        // ScreenSize
        renderEncoder.setVertexBytes(&screenSize, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
        renderEncoder.setFragmentBytes(&screenSize, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)

        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Settings.shared.maxSnowflakes)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    func updateSnowflakes() {
        let radius = influenceRadius
        var activeWindowRect: CGRect?

        if Settings.shared.windowInteraction {
            activeWindowRect = WindowInfo().getActiveWindowRect()
        }

        for i in 0..<Settings.shared.maxSnowflakes {
            var snowflake = snowflakes[i]
            let dx = mousePosition.x - snowflake.position.x
            let dy = mousePosition.y - snowflake.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < radius {
                let angle = atan2(dy, dx)
                let targetX = mousePosition.x - cos(angle) * radius
                let targetY = mousePosition.y - sin(angle) * radius

                snowflake.position.x += (targetX - snowflake.position.x) * 0.1
                snowflake.position.y += (targetY - snowflake.position.y) * 0.1
            }

            snowflake.position.y += snowflake.velocity.y
            snowflake.position.x += Float.random(in: 0.1...0.5) * Settings.shared.windStrength

            if Settings.shared.windowInteraction,
               let activeWindowRect,
               activeWindowRect.contains(CGPoint(x: CGFloat(snowflake.position.x), y: CGFloat(snowflake.position.y))) {
                snowflake.position.y = Float(activeWindowRect.origin.y)
                snowflake.size -= Settings.shared.semltingSpeed
            }

            if (snowflake.position.y - snowflake.size > screenSize.y) || !(snowflake.size > Settings.shared.snowflakeSizeRange.lowerBound - 1) {
                snowflake.clear(for: screenSize)
            }

            snowflakes[i] = snowflake
        }

        let pointer = particleBuffer.contents().bindMemory(to: Snowflake.self, capacity: Settings.shared.maxSnowflakes)
        for i in 0..<Settings.shared.maxSnowflakes {
            pointer[i] = snowflakes[i]
        }
    }
}
