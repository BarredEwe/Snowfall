import AppKit
import MetalKit

class MetalSnowViewController: NSViewController {
    private let mtkView = MTKView()
    private var renderer: SnowRenderer!
    private let screenRect: CGRect
    private let globalRect: CGRect
    private let backingScaleFactor: CGFloat
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var screensAwake = true
    private var sessionActive = true
    
    init(screenRect: CGRect, globalRect: CGRect, backingScaleFactor: CGFloat) {
        self.screenRect = screenRect
        self.globalRect = globalRect
        self.backingScaleFactor = backingScaleFactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func loadView() {
        mtkView.frame = CGRect(origin: .zero, size: screenRect.size)
        mtkView.autoresizingMask = [.width, .height]
        mtkView.autoResizeDrawable = false
        mtkView.drawableSize = SnowRenderPolicy.drawableSize(for: screenRect.size)
        mtkView.isPaused = true
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.layer?.isOpaque = false
        let metalLayer = mtkView.layer as! CAMetalLayer
        metalLayer.maximumDrawableCount = 2
        metalLayer.contentsScale = mtkView.drawableSize.width / screenRect.width
        metalLayer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        
        self.view = mtkView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        renderer = SnowRenderer(mtkView: mtkView, screenRect: screenRect, globalRect: globalRect,
                                backingScaleFactor: backingScaleFactor)
        mtkView.delegate = renderer
        
        let trackingArea = NSTrackingArea(
            rect: self.view.bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        self.view.addTrackingArea(trackingArea)
        observe(NSWindow.didChangeOcclusionStateNotification)
        observe(.NSProcessInfoPowerStateDidChange)
        observe(ProcessInfo.thermalStateDidChangeNotification)
        let workspace = NSWorkspace.shared.notificationCenter
        observe(NSWorkspace.activeSpaceDidChangeNotification, center: workspace)
        observe(NSWorkspace.screensDidSleepNotification, center: workspace) { $0.screensAwake = false }
        observe(NSWorkspace.screensDidWakeNotification, center: workspace) { $0.screensAwake = true }
        observe(NSWorkspace.sessionDidResignActiveNotification, center: workspace) { $0.sessionActive = false }
        observe(NSWorkspace.sessionDidBecomeActiveNotification, center: workspace) { $0.sessionActive = true }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        updateRenderingState()
    }

    override func viewWillDisappear() {
        pauseRendering()
        super.viewWillDisappear()
    }

    deinit {
        for (center, observer) in observers { center.removeObserver(observer) }
    }

    private func observe(_ name: Notification.Name, center: NotificationCenter = .default,
                         update: @escaping (MetalSnowViewController) -> Void = { _ in }) {
        let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            update(self)
            self.updateRenderingState()
        }
        observers.append((center, observer))
    }

    private func updateRenderingState() {
        mtkView.preferredFramesPerSecond = SnowRenderPolicy.framesPerSecond(
            lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermalState: ProcessInfo.processInfo.thermalState)
        let visible = view.window.map {
            $0.isVisible && $0.isOnActiveSpace && $0.occlusionState.contains(.visible)
        } == true
        let paused = !visible || !screensAwake || !sessionActive
        if mtkView.isPaused != paused {
            if paused {
                pauseRendering()
            } else {
                if mtkView.device == nil {
                    mtkView.device = MTLCreateSystemDefaultDevice()
                    renderer.restoreGPUResources(in: mtkView)
                }
                renderer.resetFrameTime()
                mtkView.isPaused = false
            }
        }
    }

    private func pauseRendering() {
        mtkView.isPaused = true
        mtkView.releaseDrawables()
        renderer.releaseGPUResources()
        mtkView.device = nil
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = event.locationInWindow
        let invertedY = self.view.bounds.height - location.y
        
        let point = simd_float2(Float(location.x * backingScaleFactor), Float(invertedY * backingScaleFactor))
        renderer.mousePosition = point
    }
}
