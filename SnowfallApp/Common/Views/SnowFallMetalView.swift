import SwiftUI
import MetalKit

struct SnowFallMetalView: View {
    @State var screenSize: CGSize = NSScreen.main?.frame.size ?? .zero
    @State var mousePosition: CGPoint = .zero

    var body: some View {
        SnowView(size: $screenSize, mousePosition: $mousePosition)
            .background(MouseTrackingView { position in
                mousePosition = position
            })
            .onChange(of: NSScreen.main?.frame.size ?? .zero, initial: true) { oldValue, newValue in
                guard screenSize != newValue else { return }

                screenSize = newValue
            }
            .ignoresSafeArea()
    }
}

struct SnowView: NSViewRepresentable {
    let metalView = MTKView()

    @Binding var size: CGSize
    @Binding var mousePosition: CGPoint

    class Coordinator: NSObject {
        var parent: SnowView
        var renderer: SnowRenderer

        init(parent: SnowView) {
            self.parent = parent
            self.parent.metalView.device = MTLCreateSystemDefaultDevice()
            self.parent.metalView.layer?.isOpaque = false
            self.parent.metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            self.parent.metalView.isPaused = false
            self.parent.metalView.enableSetNeedsDisplay = false
            self.renderer = SnowRenderer(mtkView: self.parent.metalView, screenSize: self.parent.size)
            self.parent.metalView.delegate = renderer
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> MTKView {
        return metalView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.renderer.mousePosition = simd_float2(Float(mousePosition.x), Float(mousePosition.y))
        context.coordinator.renderer.screenSize = simd_float2(Float(size.width), Float(size.height))
    }
}
