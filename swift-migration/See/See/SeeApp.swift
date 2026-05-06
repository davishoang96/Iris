//
//  SeeApp.swift
//  See
//
//  Created by Davis Hoang on 6/5/2026.
//

import SwiftUI

@main
struct SeeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
