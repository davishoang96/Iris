import SwiftUI

struct ViewMenuCommands: Commands {
    @FocusedValue(\.appViewModel) var appViewModel

    var body: some Commands {
        CommandMenu("View") {
            Button(appViewModel?.preferences.metaBarVisible == true ? "Hide Status Bar" : "Show Status Bar") {
                appViewModel?.preferences.metaBarVisible.toggle()
            }
            .disabled(appViewModel == nil)

            Divider()

            Button(appViewModel?.preferences.filmstripOpen == true ? "Hide Filmstrip" : "Show Filmstrip") {
                appViewModel?.preferences.filmstripOpen.toggle()
            }
            .keyboardShortcut("f", modifiers: [.command, .option])
            .disabled(appViewModel == nil)
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let appVM = AppViewModel()
    private var extraWindows: [NSWindow] = []

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        if appVM.library.folderURL == nil {
            appVM.library.openFile(url)
        } else {
            openNewWindow(for: url)
        }
    }

    private func openNewWindow(for url: URL) {
        let vm = AppViewModel()
        vm.library.openFile(url)

        let controller = NSHostingController(rootView: ContentView(state: vm))
        let window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.setContentSize(NSSize(width: 900, height: 650))
        window.center()
        window.makeKeyAndOrderFront(nil)
        extraWindows.append(window)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] note in
            self?.extraWindows.removeAll { $0 === note.object as? NSWindow }
        }
    }
}

@main
struct SeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(state: appDelegate.appVM)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            ViewMenuCommands()
        }

        Settings {
            SettingsView(preferences: appDelegate.appVM.preferences)
        }
    }
}
