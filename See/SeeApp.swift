import SwiftUI

struct ViewMenuCommands: Commands {
    @FocusedValue(\.appState) var appState

    var body: some Commands {
        CommandMenu("View") {
            Button(appState?.toolbarVisible == true ? "Hide Toolbar" : "Show Toolbar") {
                appState?.toolbarVisible.toggle()
            }
            .keyboardShortcut("t", modifiers: [.command, .option])
            .disabled(appState == nil)

            Button(appState?.metaBarVisible == true ? "Hide Status Bar" : "Show Status Bar") {
                appState?.metaBarVisible.toggle()
            }
            .disabled(appState == nil)

            Divider()

            Button(appState?.filmstripOpen == true ? "Hide Filmstrip" : "Show Filmstrip") {
                appState?.filmstripOpen.toggle()
            }
            .keyboardShortcut("f", modifiers: [.command, .option])
            .disabled(appState == nil)
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var appState = AppState()

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        appState.openFile(url)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let path = filenames.first else { return }
        appState.openFile(URL(fileURLWithPath: path))
        sender.reply(toOpenOrPrint: .success)
    }
}

@main
struct SeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(state: appDelegate.appState)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            ViewMenuCommands()
        }
    }
}
