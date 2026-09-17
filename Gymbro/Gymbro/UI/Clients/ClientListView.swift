import SwiftUI
import SwiftData

enum ClientFilter: Hashable, CaseIterable {
    case all, individual, shared, renewing
}

/// Screen 05: searchable, filterable list of clients.
struct ClientListView: View {
    @Query(sort: \Client.fullName) private var clients: [Client]
    @State private var search = ""
    @State private var filter: ClientFilter = .all
    @State private var showNewClient = false
    @State private var path = NavigationPath()
    private let calendar = Calendar.gymbro()

    var body: some View {
        NavigationStack(path: $path) {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                content(now: timeline.date)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Client.self) { client in
                ClientProfileView(client: client)
            }
            .sheet(isPresented: $showNewClient) { ClientFormView(client: nil) }
            .onAppear {
                if let name = LaunchOptions.openClientName, path.isEmpty,
                   let client = clients.first(where: { $0.fullName.localizedCaseInsensitiveContains(name) }) {
                    path.append(client)
                }
            }
        }
    }

    private func content(now: Date) -> some View {
        let active = clients.filter(\.isActive)
        let renewingCount = active.filter { $0.needsRenewal(at: now, calendar: calendar) }.count
        let visible = active.filter { matches($0, now: now) }
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(Terminology.clientsTitle)
                    .font(Theme.display(40))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button { showNewClient = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.onLime)
                        .frame(width: 52, height: 52)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.lime))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
                TextField(String(localized: "Buscar por nombre"), text: $search)
                    .font(Theme.body(19))
                    .foregroundStyle(Theme.textPrimary)
                    .tint(Theme.lime)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .cardBackground()
            .padding(.horizontal, 20)

            filterBar(renewingCount: renewingCount)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(visible) { client in
                        NavigationLink(value: client) {
                            ClientRow(client: client, now: now, calendar: calendar)
                        }
                        .buttonStyle(.plain)
                        Rectangle().fill(Theme.line).frame(height: 1)
                    }
                    if visible.isEmpty {
                        Text(String(localized: "Sin resultados"))
                            .font(Theme.body(17))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 96)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func filterBar(renewingCount: Int) -> some View {
        let labels: [(ClientFilter, String)] = [
            (.all, String(localized: "Todos")),
            (.individual, String(localized: "Individual")),
            (.shared, String(localized: "Compartido")),
            (.renewing, String(localized: "Por renovar") + (renewingCount > 0 ? " · \(renewingCount)" : "")),
        ]
        return VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(labels, id: \.0) { item in
                        Button { filter = item.0 } label: {
                            VStack(spacing: 10) {
                                Text(item.1)
                                    .font(Theme.body(17, weight: .semibold))
                                    .foregroundStyle(filter == item.0 ? Theme.textPrimary : Theme.textSecondary)
                                Rectangle()
                                    .fill(filter == item.0 ? Theme.lime : .clear)
                                    .frame(height: 3)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }

    private func matches(_ client: Client, now: Date) -> Bool {
        let query = search.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty && !client.fullName.localizedStandardContains(query) { return false }
        switch filter {
        case .all: return true
        case .individual: return (client.displayedPeriod(at: now)?.planType ?? client.planType) == .individual
        case .shared: return (client.displayedPeriod(at: now)?.planType ?? client.planType) == .shared
        case .renewing: return client.needsRenewal(at: now, calendar: calendar)
        }
    }
}

private struct ClientRow: View {
    let client: Client
    let now: Date
    let calendar: Calendar

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(Theme.body(20, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(planLine)
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            trailing
        }
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }

    private var planLine: String {
        let period = client.displayedPeriod(at: now)
        let type = UserFacingText.planType(period?.planType ?? client.planType)
        guard let period else { return type }
        return "\(type) · " + String(localized: "\(period.classCount) clases al mes")
    }

    @ViewBuilder
    private var trailing: some View {
        if let latest = client.latestPeriod, latest.endDate > now, client.needsRenewal(at: now, calendar: calendar),
           let lastDay = calendar.date(byAdding: .day, value: -1, to: latest.endDate) {
            Text(String(localized: "Vence \(DateText.shortDay(lastDay, calendar: calendar))"))
                .font(Theme.body(17, weight: .semibold))
                .foregroundStyle(Theme.coral)
        } else if let next = client.sessions.filter({ $0.status == .scheduled && $0.startsAt >= now }).min(by: { $0.startsAt < $1.startsAt }) {
            let day = calendar.isDateInToday(next.startsAt)
                ? String(localized: "hoy") : (DateText.shortWeekdays[calendar.weekday(of: next.startsAt)] ?? "")
            Text("\(day) \(DateText.time(next.startsAt, calendar: calendar))")
                .font(Theme.body(17))
                .foregroundStyle(Theme.textPrimary)
        } else {
            Text(String(localized: "Sin plan"))
                .font(Theme.body(17, weight: .semibold))
                .foregroundStyle(Theme.coral)
        }
    }
}
