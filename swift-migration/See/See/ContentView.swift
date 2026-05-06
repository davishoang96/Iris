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
    @FocusState private var detailFocused: Bool

    var body: some View {
        ZStack {
            NavigationSplitView {
                sidebar
            } detail: {
                detail
            }
            .frame(minWidth: 700, minHeight: 500)

            if state.slideshowActive, let photo = state.selectedPhoto {
                SlideshowView(photo: photo) { state.slideshowActive = false }
                    .zIndex(999)
            }
        }
    }

    // MARK: Sidebar

    @ViewBuilder
    private var sidebar: some View {
        Group {
            if state.loading {
                ProgressView("Scanning…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if state.photos.isEmpty {
                emptyListView
            } else {
                List(state.photos.indices, id: \.self, selection: $state.selectedIndex) { i in
                    photoRow(state.photos[i])
                        .tag(i)
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle(state.folderURL?.lastPathComponent ?? "See")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: state.openFolder) {
                    Label("Open Folder", systemImage: "folder")
                }
            }
        }
    }

    private func photoRow(_ photo: PhotoMeta) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(photo.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            HStack(spacing: 6) {
                if !photo.date.isEmpty {
                    Text(photo.date)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                if !photo.camera.isEmpty {
                    Text("·").foregroundStyle(.tertiary)
                    Text(photo.camera)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var emptyListView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No photos found")
                .foregroundStyle(.secondary)
            Button("Open Folder", action: state.openFolder)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        if let photo = state.selectedPhoto {
            photoDetail(photo)
        } else {
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

    private func photoDetail(_ photo: PhotoMeta) -> some View {
        VStack(spacing: 0) {
            StageView(
                photo: photo,
                rotation: $state.rotation,
                flipH: $state.flipH,
                flipV: $state.flipV,
                zoom: $state.zoom,
                zoomMode: $state.zoomMode
            )

            FilmstripView(photos: state.photos, selectedIndex: $state.selectedIndex)

            Divider()

            ScrollView {
                metaGrid(photo).padding()
            }
            .frame(maxHeight: 160)
        }
        .focusable()
        .focused($detailFocused)
        .onAppear { detailFocused = true }
        // Navigation
        .onKeyPress(.leftArrow)        { state.navigate(-1); return .handled }
        .onKeyPress(.rightArrow)       { state.navigate(+1); return .handled }
        // Zoom
        .onKeyPress(KeyEquivalent("+")) { state.nudgeZoom(+0.1); return .handled }
        .onKeyPress(KeyEquivalent("=")) { state.nudgeZoom(+0.1); return .handled }
        .onKeyPress(KeyEquivalent("-")) { state.nudgeZoom(-0.1); return .handled }
        .onKeyPress(KeyEquivalent("f")) { state.setFit(); return .handled }
        .onKeyPress(KeyEquivalent("F")) { state.setFit(); return .handled }
        .onKeyPress(KeyEquivalent("1")) { state.setHundred(); return .handled }
        // Info panel
        .onKeyPress(KeyEquivalent("i")) { state.infoOpen.toggle(); return .handled }
        .onKeyPress(KeyEquivalent("I")) { state.infoOpen.toggle(); return .handled }
        // Slideshow / escape
        .onKeyPress(.escape) {
            if state.slideshowActive { state.slideshowActive = false; return .handled }
            return .ignored
        }
        .toolbar { detailToolbar }
        .navigationTitle(photo.name)
        .navigationSubtitle("\(state.selectedIndex + 1) of \(state.photos.count)")
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        // Navigation
        ToolbarItemGroup(placement: .automatic) {
            ControlGroup {
                Button { state.navigate(-1) } label: {
                    Image(systemName: "chevron.left")
                }
                .help("Previous  ←")
                Button { state.navigate(+1) } label: {
                    Image(systemName: "chevron.right")
                }
                .help("Next  →")
            }
            .disabled(!state.hasPhotos)

            // Rotate
            ControlGroup {
                Button { state.rotation -= .degrees(90) } label: {
                    Image(systemName: "rotate.left")
                }
                .help("Rotate Left")
                Button { state.rotation += .degrees(90) } label: {
                    Image(systemName: "rotate.right")
                }
                .help("Rotate Right")
            }
            .disabled(!state.hasPhotos)

            // Flip
            ControlGroup {
                Button { state.flipH.toggle() } label: {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                }
                .help("Flip Horizontal")
                Button { state.flipV.toggle() } label: {
                    Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                }
                .help("Flip Vertical")
            }
            .disabled(!state.hasPhotos)

            // Zoom controls
            ControlGroup {
                Button { state.nudgeZoom(-0.1) } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .help("Zoom Out  −")
                Button { state.nudgeZoom(+0.1) } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .help("Zoom In  +")
            }
            .disabled(!state.hasPhotos)

            // Zoom mode
            Picker("Zoom Mode", selection: $state.zoomMode) {
                Text("Fit").tag(ZoomMode.fit)
                Text("1:1").tag(ZoomMode.hundred)
            }
            .pickerStyle(.segmented)
            .frame(width: 84)
            .help("f = Fit  ·  1 = 1:1")
            .disabled(!state.hasPhotos)
        }

        // Slideshow + Info
        ToolbarItemGroup(placement: .primaryAction) {
            Button { state.slideshowActive = true } label: {
                Image(systemName: "play.fill")
            }
            .help("Slideshow")
            .disabled(!state.hasPhotos)

            Button { state.infoOpen.toggle() } label: {
                Image(systemName: state.infoOpen ? "info.circle.fill" : "info.circle")
            }
            .help("Info Panel  i")
            .disabled(!state.hasPhotos)
        }
    }

    // MARK: EXIF grid

    private func metaGrid(_ photo: PhotoMeta) -> some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 6) {
            if !photo.camera.isEmpty   { metaRow("Camera",   photo.camera) }
            if !photo.lens.isEmpty     { metaRow("Lens",     photo.lens) }
            if !photo.focal.isEmpty    { metaRow("Focal",    photo.focal) }
            if !photo.aperture.isEmpty { metaRow("Aperture", photo.aperture) }
            if !photo.shutter.isEmpty  { metaRow("Shutter",  photo.shutter) }
            if photo.iso > 0           { metaRow("ISO",      "ISO \(photo.iso)") }
            if !photo.date.isEmpty     { metaRow("Date",     photo.date) }
            if photo.width > 0         { metaRow("Size",     "\(photo.width) × \(photo.height)") }
            if !photo.size.isEmpty     { metaRow("File",     photo.size) }
            if !photo.gps.isEmpty      { metaRow("GPS",      photo.gps) }
        }
        .font(.system(size: 12))
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .gridColumnAlignment(.leading)
        }
    }
}

#Preview {
    ContentView()
}
