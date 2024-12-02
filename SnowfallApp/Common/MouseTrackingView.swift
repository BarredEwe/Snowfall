import SwiftUI
import AppKit

struct MouseTrackingView: NSViewRepresentable {
    var onMouseMove: (CGPoint) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = MouseTrackingNSView()
        view.onMouseMove = onMouseMove
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class MouseTrackingNSView: NSView {
    var onMouseMove: ((CGPoint) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let locationInView = convert(event.locationInWindow, from: nil)

        let invertedY = self.bounds.height - locationInView.y

        onMouseMove?(CGPoint(x: locationInView.x, y: invertedY))
    }
}
