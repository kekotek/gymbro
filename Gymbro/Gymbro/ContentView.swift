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
    @State private var showSplash = true

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                AgendaView()
                    .tabItem { Label(String(localized: "Agenda"), systemImage: "calendar") }
                    .tag(MainTab.agenda)
                ClientListView()
                    .tabItem { Label(Terminology.clientsTitle, systemImage: "person.2") }
                    .tag(MainTab.clients)
            }
            .tint(Theme.lime)
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GymbroSchema.models, inMemory: true)
}
