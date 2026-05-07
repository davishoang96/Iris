import SwiftUI
import Combine

@MainActor
final class PreferencesViewModel: ObservableObject {
    @Published var filmstripOpen: Bool = UserDefaults.standard.object(forKey: "filmstripOpen") as? Bool ?? true {
        didSet { UserDefaults.standard.set(filmstripOpen, forKey: "filmstripOpen") }
    }
    @Published var toolbarVisible: Bool = UserDefaults.standard.object(forKey: "toolbarVisible") as? Bool ?? true {
        didSet { UserDefaults.standard.set(toolbarVisible, forKey: "toolbarVisible") }
    }
    @Published var metaBarVisible: Bool = UserDefaults.standard.object(forKey: "metaBarVisible") as? Bool ?? true {
        didSet { UserDefaults.standard.set(metaBarVisible, forKey: "metaBarVisible") }
    }
    @Published var theme: AppTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "") ?? .darkGrey {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") }
    }
}
