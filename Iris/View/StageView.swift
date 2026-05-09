import SwiftUI
import AppKit

private struct ScrollMonitor: NSViewRepresentable {
    let onScroll: (CGFloat, CGPoint) -> Void

    func makeNSView(context: Context) -> MonitorView { MonitorView(onScroll: onScroll) }
    func updateNSView(_ v: MonitorView, context: Context) { v.onScroll = onScroll }

    final class MonitorView: NSView {
        var onScroll: (CGFloat, CGPoint) -> Void
        private var monitor: Any?

        init(onScroll: @escaping (CGFloat, CGPoint) -> Void) {
            self.onScroll = onScroll
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, event.window === self.window else { return event }
                let loc = self.convert(event.locationInWindow, from: nil)
                guard self.bounds.contains(loc) else { return event }
                let sensitivity: CGFloat = event.hasPreciseScrollingDeltas ? 0.005 : 0.05
                let factor = exp(event.scrollingDeltaY * sensitivity)
                guard abs(factor - 1.0) > 0.001 else { return event }
                self.onScroll(factor, loc)
                return event
            }
        }

        override func viewWillMove(toWindow newWindow: NSWindow?) {
            if newWindow == nil, let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
            super.viewWillMove(toWindow: newWindow)
        }
    }
}

struct StageView: View {
    let photo: PhotoMeta
    @ObservedObject var transform: TransformViewModel
    var backgroundColor: Color = Color(red: 0.16, green: 0.16, blue: 0.16)

    @State private var nsImage: NSImage?
    @State private var panOffset: CGSize = .zero
    @State private var lastPan: CGSize = .zero
    @State private var gestureStartZoom: Double = 1.0
    @State private var inPinch: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundColor

                if let img = nsImage {
                    stageImage(img, geo: geo)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color(white: 0.6))
                }
            }
            .clipped()
            .background(
                ScrollMonitor { factor, nsLoc in
                    guard let img = nsImage else { return }
                    let fit = fitScale(img: img, container: geo.size)
                    let focal = CGPoint(
                        x: nsLoc.x - geo.size.width  / 2,
                        y: -(nsLoc.y - geo.size.height / 2)
                    )
                    let currentZoom: Double = switch transform.zoomMode {
                    case .fit:     1.0
                    case .hundred: 1.0 / fit
                    case .custom:  transform.zoom
                    }
                    let newZoom = max(0.2, min(8.0, currentZoom * Double(factor)))
                    let ratio = (fit * newZoom) / effectiveScale(fit: fit)
                    panOffset = CGSize(
                        width:  focal.x * (1 - ratio) + panOffset.width  * ratio,
                        height: focal.y * (1 - ratio) + panOffset.height * ratio
                    )
                    lastPan = panOffset
                    transform.zoom = newZoom
                    transform.zoomMode = .custom
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }
        .task(id: photo.id) {
            nsImage = nil
            panOffset = .zero
            lastPan = .zero
            nsImage = await Task.detached { ImageLoadingService.loadDisplayImage(url: photo.path) }.value
        }
        .onChange(of: transform.zoomMode) {
            if transform.zoomMode == .fit { panOffset = .zero; lastPan = .zero }
        }
    }

    @ViewBuilder
    private func stageImage(_ img: NSImage, geo: GeometryProxy) -> some View {
        let fit = fitScale(img: img, container: geo.size)
        let scale = effectiveScale(fit: fit)
        let w = img.size.width  * scale
        let h = img.size.height * scale

        Image(nsImage: img)
            .resizable()
            .frame(width: w, height: h)
            .scaleEffect(x: transform.flipH ? -1 : 1, y: transform.flipV ? -1 : 1)
            .rotationEffect(transform.rotation)
            .offset(panOffset)
            .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
            .gesture(panGesture())
            .gesture(pinchGesture(fit: fit))
    }

    private func fitScale(img: NSImage, container: CGSize) -> Double {
        guard img.size.width > 0, img.size.height > 0,
              container.width > 0, container.height > 0 else { return 1 }
        return min(container.width  / img.size.width,
                   container.height / img.size.height)
    }

    private func effectiveScale(fit: Double) -> Double {
        switch transform.zoomMode {
        case .fit:     return fit
        case .hundred: return 1.0
        case .custom:  return fit * transform.zoom
        }
    }

    private func panGesture() -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in
                panOffset = CGSize(
                    width:  lastPan.width  + v.translation.width,
                    height: lastPan.height + v.translation.height
                )
            }
            .onEnded { _ in lastPan = panOffset }
    }

    private func pinchGesture(fit: Double) -> some Gesture {
        MagnifyGesture()
            .onChanged { v in
                if !inPinch {
                    inPinch = true
                    gestureStartZoom = switch transform.zoomMode {
                    case .fit:     1.0
                    case .hundred: 1.0 / fit
                    case .custom:  transform.zoom
                    }
                }
                transform.zoom = max(0.2, min(8.0, gestureStartZoom * v.magnification))
                transform.zoomMode = .custom
            }
            .onEnded { v in
                transform.zoom = max(0.2, min(8.0, gestureStartZoom * v.magnification))
                inPinch = false
            }
    }
}
