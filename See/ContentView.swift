import SwiftUI
import AppKit
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var folderURL: URL? = nil
    @Published var photos: [PhotoMeta] = []
    @Published var loading = false

    @Published var selectedIndex: Int = 0 {
        didSet { if oldValue != selectedIndex { resetTransforms() } }
    }

    @Published var rotation: Angle = .zero
    @Published var flipH: Bool = false
    @Published var flipV: Bool = false
    @Published var zoom: Double = 1.0
    @Published var zoomMode: ZoomMode = .fit

    @Published var infoOpen: Bool = false
    @Published var filmstripOpen: Bool = true
    @Published var slideshowActive: Bool = false

    var selectedPhoto: PhotoMeta? {
        photos.indices.contains(selectedIndex) ? photos[selectedIndex] : nil
    }

    var hasPhotos: Bool { !photos.isEmpty }

    func navigate(_ delta: Int) {
        guard hasPhotos else { return }
        selectedIndex = (selectedIndex + delta + photos.count) % photos.count
    }

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

    func resetTransforms() {
        rotation = .zero
        flipH = false
        flipV = false
        zoom = 1.0
        zoomMode = .fit
    }

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a folder of photos"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        folderURL = url
        loading = true
        selectedIndex = 0

        Task.detached(priority: .userInitiated) {
            let found = scanFolder(url)
            await MainActor.run {
                self.photos = found
                self.loading = false
            }
        }
    }
}

// MARK: - Root view

struct ContentView: View {
    @StateObject private var state = AppState()
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ViewerToolbar(state: state)

                HStack(spacing: 0) {
                    mainColumn

                    if state.infoOpen, let photo = state.selectedPhoto {
                        InfoPanelView(photo: photo)
                    }
                }
            }
            .focusable()
            .focused($focused)
            .onAppear { focused = true }
            .onKeyPress(.leftArrow)          { state.navigate(-1); return .handled }
            .onKeyPress(.rightArrow)         { state.navigate(+1); return .handled }
            .onKeyPress(KeyEquivalent("+"))  { state.nudgeZoom(+0.1); return .handled }
            .onKeyPress(KeyEquivalent("="))  { state.nudgeZoom(+0.1); return .handled }
            .onKeyPress(KeyEquivalent("-"))  { state.nudgeZoom(-0.1); return .handled }
            .onKeyPress(KeyEquivalent("f"))  { state.setFit(); return .handled }
            .onKeyPress(KeyEquivalent("F"))  { state.setFit(); return .handled }
            .onKeyPress(KeyEquivalent("1"))  { state.setHundred(); return .handled }
            .onKeyPress(KeyEquivalent("i"))  { state.infoOpen.toggle(); return .handled }
            .onKeyPress(KeyEquivalent("I"))  { state.infoOpen.toggle(); return .handled }
            .onKeyPress(.escape) {
                if state.slideshowActive { state.slideshowActive = false; return .handled }
                return .ignored
            }
            .frame(minWidth: 700, minHeight: 500)

            if state.slideshowActive, let photo = state.selectedPhoto {
                SlideshowView(photo: photo) { state.slideshowActive = false }
                    .zIndex(999)
            }
        }
    }

    // MARK: Main column

    @ViewBuilder
    private var mainColumn: some View {
        if state.loading {
            ProgressView("Scanning…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if state.photos.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                if let photo = state.selectedPhoto {
                    StageView(
                        photo: photo,
                        rotation: $state.rotation,
                        flipH: $state.flipH,
                        flipV: $state.flipV,
                        zoom: $state.zoom,
                        zoomMode: $state.zoomMode
                    )
                }
                if state.filmstripOpen {
                    FilmstripView(photos: state.photos, selectedIndex: $state.selectedIndex)
                }
                MetaBarView(state: state)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("Open a folder to get started")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Open Folder", action: state.openFolder)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
