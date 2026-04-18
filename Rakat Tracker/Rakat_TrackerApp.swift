//
//  Rakat_TrackerApp.swift
//  Rakat Tracker
//
//  Created by Awni AlQuraini on 4/17/26.
//

import SwiftUI
import SwiftData

@main
struct Rakat_TrackerApp: App {
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
