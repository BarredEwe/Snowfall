import SwiftUI

struct RangedSliderView: View {
    let currentValue: Binding<ClosedRange<Float>>
    let sliderBounds: ClosedRange<Int>

    public init(value: Binding<ClosedRange<Float>>, in bounds: ClosedRange<Int>) {
        self.currentValue = value
        self.sliderBounds = bounds
    }

    var body: some View {
        GeometryReader { geomentry in
            sliderView(sliderSize: geomentry.size)

        }
        .padding(.init(top: 16, leading: 10, bottom: 6, trailing: 10))
    }


    @ViewBuilder private func sliderView(sliderSize: CGSize) -> some View {
        let sliderViewYCenter = sliderSize.height / 2
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 4)
                .padding(.horizontal, -10)

            ZStack {
                let sliderBoundDifference = sliderBounds.count
                let stepWidthInPixel = CGFloat(sliderSize.width) / CGFloat(sliderBoundDifference)

                // Calculate Left Thumb initial position
                let leftThumbLocation: CGFloat = currentValue.wrappedValue.lowerBound == Float(sliderBounds.lowerBound)
                ? 0
                : CGFloat(currentValue.wrappedValue.lowerBound - Float(sliderBounds.lowerBound)) * stepWidthInPixel

                // Calculate right thumb initial position
                let rightThumbLocation = CGFloat(currentValue.wrappedValue.upperBound) * stepWidthInPixel

                // Path between both handles
                lineBetweenThumbs(from: .init(x: leftThumbLocation, y: sliderViewYCenter), to: .init(x: rightThumbLocation, y: sliderViewYCenter))

                // Left Thumb Handle
                let leftThumbPoint = CGPoint(x: leftThumbLocation, y: sliderViewYCenter)
                thumbView(position: leftThumbPoint, value: Float(currentValue.wrappedValue.lowerBound))
                    .highPriorityGesture(DragGesture().onChanged { dragValue in

                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(0, dragLocation.x), sliderSize.width)

                        let newValue = Float(sliderBounds.lowerBound) + Float(xThumbOffset / stepWidthInPixel)

                        // Stop the range thumbs from colliding each other
                        if newValue < currentValue.wrappedValue.upperBound {
                            currentValue.wrappedValue = newValue...currentValue.wrappedValue.upperBound
                        }
                    })

                // Right Thumb Handle
                thumbView(position: CGPoint(x: rightThumbLocation, y: sliderViewYCenter), value: currentValue.wrappedValue.upperBound)
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(CGFloat(leftThumbLocation), dragLocation.x), sliderSize.width)

                        var newValue = Float(xThumbOffset / stepWidthInPixel) // convert back the value bound
                        newValue = min(newValue, Float(sliderBounds.upperBound))

                        // Stop the range thumbs from colliding each other
                        if newValue > currentValue.wrappedValue.lowerBound {
                            currentValue.wrappedValue = currentValue.wrappedValue.lowerBound...newValue
                        }
                    })
            }
        }
    }

    @ViewBuilder func lineBetweenThumbs(from: CGPoint, to: CGPoint) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }.stroke(Color.accentColor, lineWidth: 4)
    }

    @ViewBuilder func thumbView(position: CGPoint, value: Float) -> some View {
        ZStack {
            Text(String(Int(value)))
                .font(.system(size: 10, weight: .semibold))
                .offset(y: -20)
            Circle()
                .frame(width: 20, height: 20)
                .foregroundColor(Color(nsColor: NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 2)
                .contentShape(Rectangle())
        }
        .position(x: position.x, y: position.y)
    }
}
