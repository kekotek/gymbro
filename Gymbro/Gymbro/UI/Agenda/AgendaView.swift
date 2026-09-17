import SwiftUI
import SwiftData

enum AgendaMode: Hashable {
    case day
    case week
}

/// Main screen: the current week and the next four, as a week grid or a day agenda.
struct AgendaView: View {
    @State private var mode: AgendaMode = LaunchOptions.initialAgendaMode
    @State private var selectedDate = Date.now
    @State private var path = NavigationPath()
    @Environment(\.modelContext) private var modelContext
    private let calendar = Calendar.gymbro()

    var body: some View {
        NavigationStack(path: $path) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                content(now: context.date)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationDestination(for: ClassSession.self) { session in
                ClassDetailView(session: session)
            }
            .navigationDestination(for: Client.self) { client in
                ClientProfileView(client: client, backTitle: String(localized: "Clase"))
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: openClassFromLaunchOptions)
        }
    }

    private func openClassFromLaunchOptions() {
        guard path.isEmpty, let time = LaunchOptions.openClassTime else { return }
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, let start = calendar.date(day: .now, minuteOfDay: parts[0] * 60 + parts[1]) else { return }
        let predicate = #Predicate<ClassSession> { $0.startsAt == start }
        if let session = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            path.append(session)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let weeks = calendar.weeks(from: now, count: GymSchedule.visibleWeekCount)
        let shownDate = weeks.contains { $0.start <= selectedDate && selectedDate < $0.end } ? selectedDate : now
        let weekIndex = weeks.firstIndex { $0.start <= shownDate && shownDate < $0.end } ?? 0
        let week = weeks[weekIndex]

        VStack(spacing: 0) {
            header(week: week, shownDate: shownDate)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            weekNavigation(weeks: weeks, index: weekIndex, shownDate: shownDate)
                .padding(.horizontal, 12)
                .padding(.vertical, 18)
            WeekSessionsQuery(week: week) { sessions in
                switch mode {
                case .week:
                    WeekCalendarView(week: week, sessions: sessions, now: now, calendar: calendar) { day in
                        selectedDate = day
                        mode = .day
                    }
                case .day:
                    DayAgendaView(week: week, selectedDate: shownDate, sessions: sessions, now: now, calendar: calendar) { day in
                        selectedDate = day
                    }
                }
            }
            .id(week.start)
        }
    }

    private func header(week: DateInterval, shownDate: Date) -> some View {
        HStack(alignment: .center) {
            Text(mode == .week ? DateText.weekRange(week, calendar: calendar) : DateText.dayTitle(shownDate, calendar: calendar))
                .font(Theme.display(40))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 12)
            ModePicker(mode: $mode)
        }
    }

    private func weekNavigation(weeks: [DateInterval], index: Int, shownDate: Date) -> some View {
        HStack {
            Button { shift(weeks: 1, from: shownDate, direction: -1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }
            .disabled(index == 0)
            Spacer()
            Text(navigationLabel(index: index, count: weeks.count, week: weeks[index]))
                .font(Theme.body(17, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button { shift(weeks: 1, from: shownDate, direction: 1) } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44)
            }
            .disabled(index == weeks.count - 1)
        }
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(Theme.textPrimary)
    }

    private func navigationLabel(index: Int, count: Int, week: DateInterval) -> String {
        let relative: String
        switch index {
        case 0: relative = String(localized: "Esta semana")
        case 1: relative = String(localized: "Próxima semana")
        default: relative = String(localized: "En \(index) semanas")
        }
        switch mode {
        case .week: return "\(relative) · \(index + 1) de \(count)"
        case .day: return "\(relative) · \(DateText.weekRange(week, calendar: calendar))"
        }
    }

    private func shift(weeks: Int, from date: Date, direction: Int) {
        if let moved = calendar.date(byAdding: .weekOfYear, value: weeks * direction, to: date) {
            selectedDate = moved
        }
    }
}

/// Loads the classes of one week. Re-created (via `.id`) when the week changes.
private struct WeekSessionsQuery<Content: View>: View {
    @Query private var sessions: [ClassSession]
    private let content: ([ClassSession]) -> Content

    init(week: DateInterval, @ViewBuilder content: @escaping ([ClassSession]) -> Content) {
        let start = week.start
        let end = week.end
        _sessions = Query(
            filter: #Predicate<ClassSession> { $0.startsAt >= start && $0.startsAt < end },
            sort: \ClassSession.startsAt
        )
        self.content = content
    }

    var body: some View { content(sessions) }
}

private struct ModePicker: View {
    @Binding var mode: AgendaMode

    var body: some View {
        HStack(spacing: 0) {
            segment(String(localized: "Día"), .day)
            segment(String(localized: "Semana"), .week)
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
    }

    private func segment(_ title: String, _ value: AgendaMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { mode = value }
        } label: {
            Text(title)
                .font(Theme.body(16, weight: mode == value ? .bold : .medium))
                .foregroundStyle(mode == value ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 11).fill(mode == value ? Theme.surfaceRaised : .clear))
        }
        .buttonStyle(.plain)
    }
}
