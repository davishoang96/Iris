import SwiftUI

struct FileMenuCommands: Commands {
    @FocusedValue(\.appViewModel) var appViewModel

    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button("Save") { appViewModel?.save() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(appViewModel == nil)
        }
    }
}

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

    private var extraWindows: [UUID: (vm: AppViewModel, window: NSWindow)] = [:]

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Main window already showing this file
        if appVM.library.selectedPhoto?.path == url {
            mainWindow?.makeKeyAndOrderFront(nil)
            return
        }

        // Extra window already showing this file
        if let match = extraWindows.values.first(where: {
            $0.vm.library.selectedPhoto?.path == url
        }) {
            match.window.makeKeyAndOrderFront(nil)
            return
        }

        // First file -> reuse main window
        // After that -> open new window
        if appVM.library.folderURL == nil {
            appVM.library.openFile(url)

            // Force SwiftUI refresh
            if let window = mainWindow {
                let controller = NSHostingController(
                    rootView: ContentView(state: appVM)
                        .id(url.path)
                )

                window.contentViewController = controller
                window.makeKeyAndOrderFront(nil)
            }

        } else {
            openNewWindow(for: url)
        }
    }

    private var mainWindow: NSWindow? {

        let extraSet = Set(
            extraWindows.values.map { ObjectIdentifier($0.window) }
        )

        return NSApp.windows.first {
            !extraSet.contains(ObjectIdentifier($0)) && $0.isVisible
        }
    }

    private func openNewWindow(for url: URL) {

        let vm = AppViewModel()
        vm.library.openFile(url)

        let controller = NSHostingController(
            rootView: ContentView(state: vm)
                .id(url.path)
        )

        let window = NSWindow(contentViewController: controller)

        window.styleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView
        ]

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        window.setContentSize(
            NSSize(width: 900, height: 650)
        )

        window.center()
        window.makeKeyAndOrderFront(nil)

        extraWindows[vm.id] = (vm, window)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] note in

            guard let self else { return }

            self.extraWindows = self.extraWindows.filter {
                $0.value.window !== note.object as? NSWindow
            }
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
        .handlesExternalEvents(matching: [])
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            FileMenuCommands()
            ViewMenuCommands()
        }

        Settings {
            SettingsView(preferences: appDelegate.appVM.preferences)
        }
    }
}
