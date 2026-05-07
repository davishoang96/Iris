import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: PreferencesViewModel

    var body: some View {
        Form {
            Picker("Theme", selection: $preferences.theme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .padding(20)
        .frame(width: 300)
    }
}
