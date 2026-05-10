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
    @State private var gestureStartZoom: Double = 1.0
    @State private var prevMagnification: Double = 1.0
    @State private var pinchFocal: CGSize = .zero
    @State private var inPinch: Bool = false
    @State private var showPositionLabel: Bool = false
    @State private var positionFadeTask: Task<Void, Never>? = nil

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
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .gesture(pinchGesture(geo: geo))
            .overlay(alignment: .bottomTrailing) {
                if showPositionLabel, let img = nsImage {
                    positionLabel(img: img, geo: geo)
                }
            }
            .background(
                ScrollMonitor { factor, nsLoc in
                    guard nsImage != nil else { return }
                    let fit = fitScale(img: nsImage!, container: geo.size)
                    let currentZoom: Double = switch transform.zoomMode {
                    case .fit:     1.0
                    case .hundred: 1.0 / fit
                    case .custom:  transform.zoom
                    }
                    let oldScale = effectiveScale(fit: fit)
                    let newZoom = max(0.2, min(8.0, currentZoom * Double(factor)))
                    let ratio = (fit * newZoom) / oldScale
                    let focal = CGSize(
                        width:  nsLoc.x - geo.size.width  / 2,
                        height: -(nsLoc.y - geo.size.height / 2)
                    )
                    panOffset = CGSize(
                        width:  focal.width  * (1 - ratio) + panOffset.width  * ratio,
                        height: focal.height * (1 - ratio) + panOffset.height * ratio
                    )
                    transform.zoom = newZoom
                    transform.zoomMode = .custom
                    flashPositionLabel()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }
        .task(id: photo.id) {
            nsImage = nil
            panOffset = .zero
            nsImage = await Task.detached { ImageLoadingService.loadDisplayImage(url: photo.path) }.value
        }
        .onChange(of: transform.zoomMode) {
            if transform.zoomMode == .fit { panOffset = .zero }
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

    @ViewBuilder
    private func positionLabel(img: NSImage, geo: GeometryProxy) -> some View {
        let fit = fitScale(img: img, container: geo.size)
        let scale = effectiveScale(fit: fit)
        let pct = Int((scale * 100).rounded())
        let dispW = Int((img.size.width  * scale).rounded())
        let dispH = Int((img.size.height * scale).rounded())

        VStack(spacing: 2) {
            Text("\(pct)%")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
            Text("\(dispW) × \(dispH) px")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
        .allowsHitTesting(false)
        .transition(.opacity)
        .animation(.easeOut(duration: 0.2), value: showPositionLabel)
    }

    private func flashPositionLabel() {
        showPositionLabel = true
        positionFadeTask?.cancel()
        positionFadeTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            if !Task.isCancelled {
                withAnimation { showPositionLabel = false }
            }
        }
    }

    private func pinchGesture(geo: GeometryProxy) -> some Gesture {
        MagnifyGesture()
            .onChanged { v in
                guard let img = nsImage else { return }
                let fit = fitScale(img: img, container: geo.size)
                if !inPinch {
                    inPinch = true
                    prevMagnification = 1.0
                    gestureStartZoom = switch transform.zoomMode {
                    case .fit:     1.0
                    case .hundred: 1.0 / fit
                    case .custom:  transform.zoom
                    }
                    // capture focal once in ZStack coords (Y-down, same as scroll wheel)
                    pinchFocal = CGSize(
                        width:  v.startLocation.x - geo.size.width  / 2,
                        height: v.startLocation.y  - geo.size.height / 2
                    )
                }
                let factor = v.magnification / prevMagnification
                prevMagnification = v.magnification
                let currentZoom: Double = transform.zoomMode == .custom ? transform.zoom : gestureStartZoom
                let oldScale = effectiveScale(fit: fit)
                let newZoom = max(0.2, min(8.0, currentZoom * factor))
                let ratio = (fit * newZoom) / oldScale
                panOffset = CGSize(
                    width:  pinchFocal.width  * (1 - ratio) + panOffset.width  * ratio,
                    height: pinchFocal.height * (1 - ratio) + panOffset.height * ratio
                )
                transform.zoom = newZoom
                transform.zoomMode = .custom
                flashPositionLabel()
            }
            .onEnded { _ in inPinch = false }
    }
}
