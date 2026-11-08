import AppKit
import MetalKit
import simd

@main
struct RenderingRegression {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }

    static func uniforms() -> SnowUniforms {
        SnowUniforms(screenSize: SIMD2(1920, 1080), mousePosition: SIMD2(-1000, -1000),
                     windowRect: SIMD4(100, 100, 100, 50), time: 10, deltaTime: 1 / 30,
                     windStrength: 1, minSize: 3, maxSize: 15, minSpeed: 0.5, maxSpeed: 3,
                     isWindowInteractionEnabled: true, particleCount: 2000, renderScale: 0.5)
    }

    static func flake(_ x: Float, _ y: Float, size: Float = 10) -> Snowflake {
        Snowflake(position: SIMD2(x, y), velocity: SIMD2(0, 2), color: SIMD4(repeating: 1), size: size)
    }

    static func testSimulation() {
        var u = uniforms()
        var flakes = [flake(200, 300), flake(150, 120), flake(150, 120, size: 0.6),
                      flake(100, 1100), flake(2200, 300), flake(-300, 300)]
        SnowSimulation.update(&flakes, uniforms: u)
        expect(simd_distance(flakes[0].position, SIMD2(201, 304)) < 0.001, "Falling speed/wind changed")
        expect(abs(flakes[1].position.y - 120.4) < 0.001 && abs(flakes[1].size - 9.8) < 0.001,
               "Window collision/melting changed")
        expect(flakes[2].position.y == -10 && (3...15).contains(flakes[2].size), "Melted particle did not respawn")
        expect(flakes[3].position.y == -10 && (-200...2120).contains(flakes[3].position.x), "Bottom wrapping changed")
        expect(flakes[4].position.x == -100 && flakes[5].position.x == 2020, "Horizontal wrapping changed")
        u.isWindowInteractionEnabled = false
        var oneStep = [flake(150, 120)]
        var twoSteps = oneStep
        SnowSimulation.update(&oneStep, uniforms: u)
        u.deltaTime = 1 / 60
        SnowSimulation.update(&twoSteps, uniforms: u)
        SnowSimulation.update(&twoSteps, uniforms: u)
        expect(simd_distance(oneStep[0].position, twoSteps[0].position) < 0.001,
               "30 FPS changed particle travel speed")
        u.windStrength = 0
        u.mousePosition = SIMD2(50, 50)
        var mouse = [flake(50, 50), flake(75, 50)]
        mouse[0].velocity = .zero
        mouse[1].velocity = .zero
        SnowSimulation.update(&mouse, uniforms: u)
        expect(mouse[0].position == SIMD2(50, 50), "Mouse center produced NaN")
        expect(mouse[1].position == SIMD2(85, 50), "Mouse repulsion changed")
        for count in [800, 2000, 6000, 10_000] {
            let particles = SnowSimulation.initialize(count: count, uniforms: u)
            expect(particles.count == count && particles.allSatisfy {
                (3...15).contains($0.size) && (0.5...3).contains($0.velocity.y)
                    && $0.position.x.isFinite && $0.position.y.isFinite
            }, "Preset initialization violated its ranges")
        }
    }

    static func testResolutionAndEnergyPolicy() {
        for size in [CGSize(width: 1728, height: 1117), CGSize(width: 3840, height: 2160),
                     CGSize(width: 2160, height: 3840), CGSize(width: 7680, height: 4320)] {
            let drawable = SnowRenderPolicy.drawableSize(for: size)
            expect(drawable.width * drawable.height <= SnowRenderPolicy.maximumDrawablePixels,
                   "Drawable exceeded the memory budget")
            expect(abs(drawable.width / drawable.height - size.width / size.height) < 0.003,
                   "Rendering distorted the display aspect ratio")
        }
        expect(SnowRenderPolicy.framesPerSecond(lowPower: false, thermalState: .nominal) == 30, "Normal FPS")
        expect(SnowRenderPolicy.framesPerSecond(lowPower: true, thermalState: .nominal) == 20, "Low power FPS")
        expect(SnowRenderPolicy.framesPerSecond(lowPower: false, thermalState: .serious) == 20, "Thermal FPS")
    }

    static func testRenderingLifecycle(completion: @escaping () -> Void) {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let rect = CGRect(x: 0, y: 0, width: 320, height: 180)
        let controller = MetalSnowViewController(screenRect: rect, globalRect: rect, backingScaleFactor: 2)
        let window = NSWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
        window.contentViewController = controller
        window.orderFrontRegardless()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let view = controller.view as! MTKView
            expect(view.device!.makeDefaultLibrary()!.makeFunction(name: "vertex_main") != nil,
                   "Compiled Metal library is missing")
            expect(!view.isPaused, "Visible overlay did not start rendering (visible=\(window.isVisible), activeSpace=\(window.isOnActiveSpace), occlusion=\(window.occlusionState.rawValue))")
            expect(view.drawableSize == rect.size, "Retina drawable unexpectedly grew")
            let workspace = NSWorkspace.shared.notificationCenter
            workspace.post(name: NSWorkspace.screensDidSleepNotification, object: nil)
            expect(view.isPaused, "Sleeping display kept rendering")
            expect(view.device == nil, "Sleeping display retained Metal resources")
            view.delegate?.draw(in: view) // A timer callback can already be queued when sleep arrives.
            workspace.post(name: NSWorkspace.screensDidWakeNotification, object: nil)
            expect(!view.isPaused, "Display wake did not resume rendering")
            expect(view.device != nil, "Display wake did not recreate Metal resources")
            workspace.post(name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
            expect(view.isPaused, "Inactive session kept rendering")
            workspace.post(name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
            expect(!view.isPaused, "Active session did not resume rendering")
            window.orderOut(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                expect(view.isPaused, "Hidden overlay kept rendering")
                window.close()
                completion()
            }
        }
    }

    static func testMetalOutput() throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = device.makeDefaultLibrary()!
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertex_main")
        descriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        let pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        let queue = device.makeCommandQueue(maxCommandBufferCount: 1)!
        var particle = flake(32, 32, size: 12)
        let buffer = device.makeBuffer(bytes: &particle, length: MemoryLayout<Snowflake>.stride,
                                       options: .storageModeShared)!
        var areas: [Double] = []
        for dimension in [64, 32] {
            let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                              width: dimension, height: dimension, mipmapped: false)
            td.storageMode = .shared
            td.usage = .renderTarget
            let texture = device.makeTexture(descriptor: td)!
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = texture
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].storeAction = .store
            pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
            var u = uniforms()
            u.screenSize = SIMD2(repeating: 64)
            u.renderScale = Float(dimension) / 64
            let command = queue.makeCommandBuffer()!
            let encoder = command.makeRenderCommandEncoder(descriptor: pass)!
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.setVertexBytes(&u, length: MemoryLayout<SnowUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1)
            encoder.endEncoding()
            command.commit()
            command.waitUntilCompleted()
            expect(command.status == .completed, "Metal draw failed")
            var pixels = [UInt8](repeating: 0, count: dimension * dimension * 4)
            texture.getBytes(&pixels, bytesPerRow: dimension * 4,
                             from: MTLRegionMake2D(0, 0, dimension, dimension), mipmapLevel: 0)
            let area = stride(from: 3, to: pixels.count, by: 4).reduce(0.0) { $0 + Double(pixels[$1]) / 255 }
            areas.append(area)
        }
        expect(areas[0] > 50 && areas[0] < 130, "Snow sprite is missing or malformed")
        expect(abs(areas[1] * 4 / areas[0] - 1) < 0.3, "Reduced resolution changed apparent snowflake size")
        let result = buffer.contents().assumingMemoryBound(to: Snowflake.self).pointee
        expect(result.position == particle.position && result.size == particle.size, "Renderer mutated simulation state")
    }

    static func main() throws {
        testSimulation()
        testResolutionAndEnergyPolicy()
        try testMetalOutput()
        let app = NSApplication.shared
        DispatchQueue.main.async {
            testRenderingLifecycle {
                print("PASS: simulation, render budget, frame-rate policy, lifecycle and Metal pixel output")
                exit(0)
            }
        }
        app.run()
    }
}
