import SwiftUI
import AppKit

enum ZoomMode { case fit, hundred, custom }

struct StageView: View {
    let photo: PhotoMeta
    @Binding var rotation: Angle
    @Binding var flipH: Bool
    @Binding var flipV: Bool
    @Binding var zoom: Double
    @Binding var zoomMode: ZoomMode

    @State private var nsImage: NSImage?
    @State private var panOffset: CGSize = .zero
    @State private var lastPan: CGSize = .zero
    @State private var gestureStartZoom: Double = 1.0
    @State private var inPinch: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.16, green: 0.16, blue: 0.16)

                if let img = nsImage {
                    stageImage(img, geo: geo)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color(white: 0.6))
                }
            }
            .clipped()
        }
        .task(id: photo.id) {
            nsImage = nil
            panOffset = .zero
            lastPan = .zero
            nsImage = await loadImage(from: photo.path)
        }
        .onChange(of: zoomMode) {
            if zoomMode == .fit { panOffset = .zero; lastPan = .zero }
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
            .scaleEffect(x: flipH ? -1 : 1, y: flipV ? -1 : 1)
            .rotationEffect(rotation)
            .offset(panOffset)
            .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
            .gesture(panGesture())
            .gesture(pinchGesture(fit: fit))

        // dimension badge
        if img.size.width > 0 {
            let px = photo.width > 0 ? photo.width : Int(img.size.width)
            let py = photo.height > 0 ? photo.height : Int(img.size.height)
            VStack {
                HStack {
                    Spacer()
                    Text("\(px) × \(py)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(12)
                }
                Spacer()
            }
        }
    }

    private func fitScale(img: NSImage, container: CGSize) -> Double {
        guard img.size.width > 0, img.size.height > 0,
              container.width > 0, container.height > 0 else { return 1 }
        return min(container.width  / img.size.width,
                   container.height / img.size.height)
    }

    private func effectiveScale(fit: Double) -> Double {
        switch zoomMode {
        case .fit:     return fit
        case .hundred: return 1.0
        case .custom:  return fit * zoom
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
                    gestureStartZoom = switch zoomMode {
                    case .fit:     1.0
                    case .hundred: 1.0 / fit
                    case .custom:  zoom
                    }
                }
                zoom = max(0.2, min(8.0, gestureStartZoom * v.magnification))
                zoomMode = .custom
            }
            .onEnded { v in
                zoom = max(0.2, min(8.0, gestureStartZoom * v.magnification))
                inPinch = false
            }
    }
}

private func loadImage(from url: URL) async -> NSImage? {
    await Task.detached { loadDisplayImage(url: url) }.value
}
