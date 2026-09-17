//
//  GymbroApp.swift
//  Gymbro
//

import SwiftUI
import SwiftData

@main
struct GymbroApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: GymbroSchema.models)
    }
}
