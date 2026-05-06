import SwiftUI
import AppKit
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var folderURL: URL? = nil
    @Published var photos: [PhotoMeta] = []
    @Published var selectedIndex: Int = 0
    @Published var loading = false

    var selectedPhoto: PhotoMeta? {
        photos.indices.contains(selectedIndex) ? photos[selectedIndex] : nil
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

struct ContentView: View {
    @StateObject private var state = AppState()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    // MARK: Sidebar — photo list

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
                    Text("·")
                        .foregroundStyle(.tertiary)
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

    // MARK: Detail — photo info

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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // placeholder for stage — Phase 2
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.16))
                    .frame(height: 320)
                    .overlay {
                        Text(photo.name)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding()

                metaGrid(photo)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationTitle(photo.name)
        .navigationSubtitle("\(state.selectedIndex + 1) of \(state.photos.count)")
    }

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
