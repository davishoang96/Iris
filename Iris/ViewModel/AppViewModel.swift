import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    let id          = UUID()
    let library     = LibraryViewModel()
    let transform   = TransformViewModel()
    let preferences = PreferencesViewModel()

    @Published var infoOpen: Bool = false
    @Published var slideshowActive: Bool = false
    @Published var saveError: String? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Propagate sub-VM changes so views observing AppViewModel re-render
        library.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        transform.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        preferences.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Reset transforms whenever the selected image changes
        library.$selectedIndex
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in self?.transform.reset() }
            .store(in: &cancellables)

        // Auto-save when transforms change and file is writable
        Publishers.CombineLatest3(transform.$rotation, transform.$flipH, transform.$flipV)
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] rotation, flipH, flipV in
                guard let self else { return }
                guard rotation != .zero || flipH || flipV else { return }
                guard let photo = library.selectedPhoto else { return }
                guard ImageSavingService.isWritable(url: photo.path) else { return }
                save()
            }
            .store(in: &cancellables)
    }

    func save() {
        guard let photo = library.selectedPhoto else { return }
        guard transform.rotation != .zero || transform.flipH || transform.flipV else { return }
        let url = photo.path
        let rotation = transform.rotation
        let flipH = transform.flipH
        let flipV = transform.flipV
        Task.detached {
            do {
                try ImageSavingService.save(url: url, rotation: rotation, flipH: flipH, flipV: flipV)
                await MainActor.run { self.saveError = nil }
            } catch {
                await MainActor.run { self.saveError = error.localizedDescription }
            }
        }
    }
}
