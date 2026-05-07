import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var folderURL: URL? = nil
    @Published var photos: [PhotoMeta] = []
    @Published var loading = false
    @Published var selectedIndex: Int = 0

    var selectedPhoto: PhotoMeta? {
        photos.indices.contains(selectedIndex) ? photos[selectedIndex] : nil
    }

    var hasPhotos: Bool { !photos.isEmpty }

    func navigate(_ delta: Int) {
        guard hasPhotos else { return }
        selectedIndex = (selectedIndex + delta + photos.count) % photos.count
    }

    func openFile(_ url: URL) {
        let folder = url.deletingLastPathComponent()
        folderURL = folder
        loading = true
        selectedIndex = 0

        Task.detached(priority: .userInitiated) {
            let found = PhotoLibraryService.scan(folder: folder)
            let target = found.firstIndex(where: { $0.path == url }) ?? 0
            await MainActor.run {
                self.photos = found
                self.selectedIndex = target
                self.loading = false
            }
        }
    }

    func openFolder() {
        guard let url = PhotoLibraryService.presentFolderPanel() else { return }
        folderURL = url
        loading = true
        selectedIndex = 0

        Task.detached(priority: .userInitiated) {
            let found = PhotoLibraryService.scan(folder: url)
            await MainActor.run {
                self.photos = found
                self.loading = false
            }
        }
    }
}
