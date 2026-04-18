//
//  RakatTrackerWatchApp.swift
//  Rakat Tracker Watch App
//

import SwiftUI
import SwiftData

@main
struct RakatTrackerWatchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RakatTrackerState.self,
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
            WatchRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
