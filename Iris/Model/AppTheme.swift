import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case darkGrey = "Dark Grey"
    case amoled   = "AMOLED"

    var stageBackground: Color {
        switch self {
        case .darkGrey: Color(red: 0.16, green: 0.16, blue: 0.16)
        case .amoled:   .black
        }
    }

    var windowBackground: Color {
        switch self {
        case .darkGrey: .clear
        case .amoled:   .black
        }
    }
}
