import SwiftUI
import AppKit
import Combine

enum AppTheme: String, CaseIterable, Codable {
    case darkGrey = "Dark Grey"
    case amoled   = "AMOLED"

    var stageBackground: Color {
        switch self {
        case .darkGrey: Color(red: 0.16, green: 0.16, blue: 0.16)
        case .amoled:   .black
        }
    }

    var windowBackground: Color {
        switch self {
        case .darkGrey: .clear
        case .amoled:   .black
        }
    }
}

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
    @Published var slideshowActive: Bool = false

    @Published var filmstripOpen: Bool = UserDefaults.standard.object(forKey: "filmstripOpen") as? Bool ?? true {
        didSet { UserDefaults.standard.set(filmstripOpen, forKey: "filmstripOpen") }
    }
    @Published var toolbarVisible: Bool = UserDefaults.standard.object(forKey: "toolbarVisible") as? Bool ?? true {
        didSet { UserDefaults.standard.set(toolbarVisible, forKey: "toolbarVisible") }
    }
    @Published var metaBarVisible: Bool = UserDefaults.standard.object(forKey: "metaBarVisible") as? Bool ?? true {
        didSet { UserDefaults.standard.set(metaBarVisible, forKey: "metaBarVisible") }
    }
    @Published var theme: AppTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "") ?? .darkGrey {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") }
    }

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

    func openFile(_ url: URL) {
        let folder = url.deletingLastPathComponent()
        folderURL = folder
        loading = true
        selectedIndex = 0
        resetTransforms()

        Task.detached(priority: .userInitiated) {
            let found = scanFolder(folder)
            let target = found.firstIndex(where: { $0.path == url }) ?? 0
            await MainActor.run {
                self.photos = found
                self.selectedIndex = target
                self.loading = false
            }
        }
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

// MARK: - Focused values

extension FocusedValues {
    @Entry var appState: AppState? = nil
}

// MARK: - Root view

struct ContentView: View {
    @ObservedObject var state: AppState
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            state.theme.windowBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if state.toolbarVisible {
                    ViewerToolbar(state: state)
                }

                HStack(spacing: 0) {
                    mainColumn

                    if state.infoOpen, let photo = state.selectedPhoto {
                        InfoPanelView(photo: photo)
                    }
                }
            }
            .focusable()
            .focusEffectDisabled()
            .focused($focused)
            .onAppear {
                focused = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if state.folderURL == nil { state.openFolder() }
                }
            }
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
            .focusedValue(\.appState, state)
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
                        zoomMode: $state.zoomMode,
                        backgroundColor: state.theme.stageBackground
                    )
                }
                if state.filmstripOpen {
                    FilmstripView(photos: state.photos, selectedIndex: $state.selectedIndex)
                }
                if state.metaBarVisible {
                    MetaBarView(state: state)
                }
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
    ContentView(state: AppState())
}
