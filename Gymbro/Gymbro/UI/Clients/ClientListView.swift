import SwiftUI
import SwiftData

/// Alphabetical list of clients with their plan and next class.
struct ClientListView: View {
    @Query(sort: \Client.fullName) private var clients: [Client]
    private let calendar = Calendar.gymbro()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(Terminology.clientsTitle)
                    .font(Theme.display(40))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(clients) { client in
                            ClientRow(client: client, now: .now, calendar: calendar)
                            Rectangle().fill(Theme.line).frame(height: 1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 96)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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
    }

    private var planLine: String {
        let period = client.latestPeriod
        let type = (period?.planType ?? client.planType) == .individual
            ? String(localized: "Individual") : String(localized: "Compartido")
        guard let period else { return type }
        return "\(type) · " + String(localized: "\(period.classCount) clases al mes")
    }

    @ViewBuilder
    private var trailing: some View {
        if let period = client.latestPeriod, period.endDate > now,
           let lastDay = calendar.date(byAdding: .day, value: -1, to: period.endDate),
           let inAWeek = calendar.date(byAdding: .day, value: 7, to: now), period.endDate <= inAWeek {
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
                .font(Theme.body(17))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
