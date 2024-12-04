import AppKit

class DisplayLink {
    let timer: CVDisplayLink
    let source: DispatchSourceUserDataAdd

    var callback : Optional<() -> ()> = nil

    var running : Bool { CVDisplayLinkIsRunning(timer) }

    init?(onQueue queue: DispatchQueue = DispatchQueue.main) {
        source = DispatchSource.makeUserDataAddSource(queue: queue)
        var timerRef : CVDisplayLink? = nil
        var successLink = CVDisplayLinkCreateWithActiveCGDisplays(&timerRef)

        if let timer = timerRef {
            successLink = CVDisplayLinkSetOutputCallback(timer, {
                (timer : CVDisplayLink, currentTime : UnsafePointer<CVTimeStamp>, outputTime : UnsafePointer<CVTimeStamp>, _ : CVOptionFlags, _ : UnsafeMutablePointer<CVOptionFlags>, sourceUnsafeRaw : UnsafeMutableRawPointer?) -> CVReturn in

                if let sourceUnsafeRaw = sourceUnsafeRaw {
                    let sourceUnmanaged = Unmanaged<DispatchSourceUserDataAdd>.fromOpaque(sourceUnsafeRaw)
                    sourceUnmanaged.takeUnretainedValue().add(data: 1)
                }

                return kCVReturnSuccess

            }, Unmanaged.passUnretained(source).toOpaque())

            guard successLink == kCVReturnSuccess else {
                NSLog("Failed to create timer with active display")
                return nil
            }

            successLink = CVDisplayLinkSetCurrentCGDisplay(timer, CGMainDisplayID())

            guard successLink == kCVReturnSuccess else {
                NSLog("Failed to connect to display")
                return nil
            }

            self.timer = timer
        } else {
            NSLog("Failed to create timer with active display")
            return nil
        }

        source.setEventHandler {
            [weak self] in self?.callback?()
        }
    }

    func start() {
        guard !running else { return }

        CVDisplayLinkStart(timer)
        source.resume()
    }

    func cancel() {
        guard running else { return }

        CVDisplayLinkStop(timer)
        source.cancel()
    }

    deinit {
        if running {
            cancel()
        }
    }
}
