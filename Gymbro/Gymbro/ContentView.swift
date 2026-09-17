//
//  ContentView.swift
//  Gymbro
//

import SwiftUI
import SwiftData

enum MainTab: Hashable {
    case agenda
    case clients
}

struct ContentView: View {
    @State private var selectedTab = LaunchOptions.initialTab

    var body: some View {
        TabView(selection: $selectedTab) {
            AgendaView()
                .tabItem { Label(String(localized: "Agenda"), systemImage: "calendar") }
                .tag(MainTab.agenda)
            ClientListView()
                .tabItem { Label(Terminology.clientsTitle, systemImage: "person.2") }
                .tag(MainTab.clients)
        }
        .tint(Theme.lime)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GymbroSchema.models, inMemory: true)
}
