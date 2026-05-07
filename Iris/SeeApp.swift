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
    var appVM = AppViewModel()

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        appVM.library.openFile(url)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let path = filenames.first else { return }
        appVM.library.openFile(URL(fileURLWithPath: path))
        sender.reply(toOpenOrPrint: .success)
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
