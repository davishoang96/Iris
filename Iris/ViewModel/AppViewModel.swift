import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    let library     = LibraryViewModel()
    let transform   = TransformViewModel()
    let preferences = PreferencesViewModel()

    @Published var infoOpen: Bool = false
    @Published var slideshowActive: Bool = false

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
    }
}
