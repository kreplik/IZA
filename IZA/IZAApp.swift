//
//  IZAApp.swift
//  IZA
//
//  Created by Adam Nieslanik on 13.05.2024.
//

import SwiftUI
import SwiftData

@main
struct IZAApp: App {
    @StateObject var dm = DarkModeModel.shared
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ListModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(dm.darkMode ? .dark : .light)
        }
        .modelContainer(sharedModelContainer)
    }
}
