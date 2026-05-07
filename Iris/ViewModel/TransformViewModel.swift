import SwiftUI
import Combine

@MainActor
final class TransformViewModel: ObservableObject {
    @Published var rotation: Angle = .zero
    @Published var flipH: Bool = false
    @Published var flipV: Bool = false
    @Published var zoom: Double = 1.0
    @Published var zoomMode: ZoomMode = .fit

    func nudgeZoom(_ delta: Double) {
        if zoomMode != .custom { zoom = 1.0 }
        zoom = max(0.2, min(8.0, zoom + delta))
        zoomMode = .custom
    }

    func setFit() {
        zoomMode = .fit
        zoom = 1.0
    }

    func setHundred() {
        zoomMode = .hundred
        zoom = 1.0
    }

    func reset() {
        rotation = .zero
        flipH = false
        flipV = false
        zoom = 1.0
        zoomMode = .fit
    }
}
