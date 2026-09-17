//
//  GymbroApp.swift
//  Gymbro
//

import SwiftUI
import SwiftData

@main
struct GymbroApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: GymbroSchema.schema)
        } catch {
            fatalError("Could not create the model container: \(error)")
        }
        #if DEBUG
        SampleData.seedIfNeeded(in: container.mainContext)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
