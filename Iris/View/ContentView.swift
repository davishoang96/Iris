import SwiftUI
import Combine

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
                if state.preferences.toolbarVisible {
                    ViewerToolbar(state: state)
                }

                HStack(spacing: 0) {
                    mainColumn

                    if state.infoOpen, let photo = state.library.selectedPhoto {
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
                    if state.library.folderURL == nil { state.library.openFolder() }
                }
            }
            .onKeyPress(.leftArrow)          { state.library.navigate(-1); return .handled }
            .onKeyPress(.rightArrow)         { state.library.navigate(+1); return .handled }
            .onKeyPress(KeyEquivalent("+"))  { state.transform.nudgeZoom(+0.1); return .handled }
            .onKeyPress(KeyEquivalent("="))  { state.transform.nudgeZoom(+0.1); return .handled }
            .onKeyPress(KeyEquivalent("-"))  { state.transform.nudgeZoom(-0.1); return .handled }
            .onKeyPress(KeyEquivalent("f"))  { state.transform.setFit(); return .handled }
            .onKeyPress(KeyEquivalent("F"))  { state.transform.setFit(); return .handled }
            .onKeyPress(KeyEquivalent("1"))  { state.transform.setHundred(); return .handled }
            .onKeyPress(KeyEquivalent("i"))  { state.infoOpen.toggle(); return .handled }
            .onKeyPress(KeyEquivalent("I"))  { state.infoOpen.toggle(); return .handled }
            .onKeyPress(.escape) {
                if state.slideshowActive { state.slideshowActive = false; return .handled }
                return .ignored
            }
            .focusedValue(\.appViewModel, state)
            .frame(minWidth: 700, minHeight: 500)

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
                        rotation: Binding(get: { state.transform.rotation },
                                          set: { state.transform.rotation = $0 }),
                        flipH:    Binding(get: { state.transform.flipH },
                                          set: { state.transform.flipH = $0 }),
                        flipV:    Binding(get: { state.transform.flipV },
                                          set: { state.transform.flipV = $0 }),
                        zoom:     Binding(get: { state.transform.zoom },
                                          set: { state.transform.zoom = $0 }),
                        zoomMode: Binding(get: { state.transform.zoomMode },
                                          set: { state.transform.zoomMode = $0 }),
                        backgroundColor: state.preferences.theme.stageBackground
                    )
                }
                if state.preferences.filmstripOpen {
                    FilmstripView(
                        photos: state.library.photos,
                        selectedIndex: Binding(
                            get: { state.library.selectedIndex },
                            set: { state.library.selectedIndex = $0 }
                        )
                    )
                }
                if state.preferences.metaBarVisible {
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
            Button("Open Folder", action: state.library.openFolder)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView(state: AppViewModel())
}
