import SwiftUI

// MARK: - Focused values

extension FocusedValues {
    @Entry var appViewModel: AppViewModel? = nil
}

// MARK: - Root view

struct ContentView: View {
    @ObservedObject var state: AppViewModel
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            state.preferences.theme.windowBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ViewerToolbar(
                    library: state.library,
                    transform: state.transform,
                    preferences: state.preferences,
                    infoOpen: $state.infoOpen,
                    slideshowActive: $state.slideshowActive,
                    onSave: { state.save() }
                )

                HStack(spacing: 0) {
                    mainColumn

                    if state.infoOpen, let photo = state.library.selectedPhoto {
                        InfoPanelView(photo: photo)
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .top)
            .focusable()
            .focusEffectDisabled()
            .focused($focused)
            .onAppear {
                focused = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if state.library.folderURL == nil { state.library.openFolder() }
                }
            }
            .onKeyPress(.leftArrow)         { state.library.navigate(-1); return .handled }
            .onKeyPress(.rightArrow)        { state.library.navigate(+1); return .handled }
            .onKeyPress(KeyEquivalent("+")) { state.transform.nudgeZoom(+0.1); return .handled }
            .onKeyPress(KeyEquivalent("=")) { state.transform.nudgeZoom(+0.1); return .handled }
            .onKeyPress(KeyEquivalent("-")) { state.transform.nudgeZoom(-0.1); return .handled }
            .onKeyPress(KeyEquivalent("f")) { state.transform.setFit(); return .handled }
            .onKeyPress(KeyEquivalent("F")) { state.transform.setFit(); return .handled }
            .onKeyPress(KeyEquivalent("1")) { state.transform.setHundred(); return .handled }
            .onKeyPress(KeyEquivalent("i")) { state.infoOpen.toggle(); return .handled }
            .onKeyPress(KeyEquivalent("I")) { state.infoOpen.toggle(); return .handled }
            .onKeyPress(.escape) {
                if state.slideshowActive { state.slideshowActive = false; return .handled }
                return .ignored
            }
            .focusedValue(\.appViewModel, state)
            .frame(minWidth: 700, minHeight: 500)
            .alert("Save Failed", isPresented: Binding(
                get: { state.saveError != nil },
                set: { if !$0 { state.saveError = nil } }
            )) {
                Button("OK") { state.saveError = nil }
            } message: {
                Text(state.saveError ?? "")
            }

            if state.slideshowActive, let photo = state.library.selectedPhoto {
                SlideshowView(photo: photo) { state.slideshowActive = false }
                    .zIndex(999)
            }
        }
    }

    // MARK: Main column

    @ViewBuilder
    private var mainColumn: some View {
        if state.library.loading {
            ProgressView("Scanning…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if state.library.photos.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                if let photo = state.library.selectedPhoto {
                    StageView(
                        photo: photo,
                        transform: state.transform,
                        backgroundColor: state.preferences.theme.stageBackground
                    )
                }
                if state.preferences.filmstripOpen {
                    FilmstripView(library: state.library)
                }
                if state.preferences.metaBarVisible {
                    MetaBarView(
                        photo: state.library.selectedPhoto,
                        index: state.library.selectedIndex,
                        total: state.library.photos.count
                    )
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
            Button("Open Folder", action: state.library.openFolder)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView(state: AppViewModel())
}
