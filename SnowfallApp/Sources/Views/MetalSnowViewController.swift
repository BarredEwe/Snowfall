import AppKit
import MetalKit

class MetalSnowViewController: NSViewController {
    private let mtkView = MTKView()
    private var renderer: SnowRenderer!
    private let screenRect: CGRect
    private let globalRect: CGRect
    
    init(screenRect: CGRect, globalRect: CGRect) {
        self.screenRect = screenRect
        self.globalRect = globalRect
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func loadView() {
        self.view = NSView(frame: CGRect(origin: .zero, size: screenRect.size))
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        mtkView.frame = self.view.bounds
        mtkView.autoresizingMask = [.width, .height]
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.layer?.isOpaque = false
        
        self.view.addSubview(mtkView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        renderer = SnowRenderer(mtkView: mtkView, screenRect: screenRect, globalRect: globalRect)
        renderer.mtkView(mtkView, drawableSizeWillChange: screenRect.size)
        mtkView.delegate = renderer
        
        let trackingArea = NSTrackingArea(
            rect: self.view.bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        self.view.addTrackingArea(trackingArea)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = event.locationInWindow
        let invertedY = self.view.bounds.height - location.y
        
        let point = simd_float2(Float(location.x), Float(invertedY))
        renderer.mousePosition = point
    }
}
