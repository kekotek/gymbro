import SwiftUI

/// One day, hour by hour. Past classes show only names; pending ones add the routine.
struct DayAgendaView: View {
    let week: DateInterval
    let selectedDate: Date
    let sessions: [ClassSession]
    let now: Date
    let calendar: Calendar
    let onSelectDay: (Date) -> Void

    private let hourHeight: CGFloat = 88
    private let gutter: CGFloat = 64
    private var hours: [Int] { Array((GymSchedule.openingMinute / 60)...(GymSchedule.closingMinute / 60)) }
    private var gridHeight: CGFloat { CGFloat(hours.count - 1) * hourHeight }

    var body: some View {
        let groups = SessionGroup.groups(from: sessions.filter { calendar.isDate($0.startsAt, inSameDayAs: selectedDate) }, calendar: calendar)
        let isToday = calendar.isDate(selectedDate, inSameDayAs: now)
        VStack(spacing: 12) {
            WeekdayStrip(week: week, highlightedDate: selectedDate, calendar: calendar, onSelect: onSelectDay)
                .padding(.horizontal, 8)
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(hours, id: \.self) { hour in
                            hourRow(hour)
                        }
                    }
                    .overlay(alignment: .top) {
                        ZStack(alignment: .top) {
                            ForEach(groups) { group in
                                let minute = calendar.minuteOfDay(of: group.startsAt)
                                if minute % 60 != 0 {
                                    timeLabel(DateText.timeOfDay(minute), color: Theme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, y(minute: minute))
                                }
                                NavigationLink(value: group.sessions[0]) {
                                    DaySessionCard(group: group, now: now, calendar: calendar)
                                }
                                .buttonStyle(.plain)
                                .frame(height: hourHeight - 8)
                                .padding(.leading, gutter)
                                .padding(.trailing, 16)
                                .padding(.top, y(minute: minute) + 4)
                            }
                            if isToday {
                                nowLine
                            }
                        }
                    }
                    .padding(.bottom, 96)
                }
                .contentMargins(.top, 14, for: .scrollContent)
                .task(id: selectedDate) {
                    // Wait one runloop turn so the grid is laid out before scrolling.
                    try? await Task.sleep(for: .milliseconds(80))
                    let target = isToday ? max(hours[0], calendar.component(.hour, from: now) - 1) : hours[0]
                    withAnimation(nil) { proxy.scrollTo(anchor(target), anchor: .top) }
                }
            }
        }
        .padding(.leading, 12)
    }

    private func hourRow(_ hour: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            timeLabel(DateText.timeOfDay(hour * 60), color: Theme.textPrimary)
            Rectangle().fill(Theme.line).frame(height: 1).padding(.trailing, 16)
        }
        .frame(height: hour == hours.last ? 24 : hourHeight, alignment: .top)
        .id(anchor(hour))
    }

    private func timeLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(Theme.heading(17))
            .foregroundStyle(color)
            .frame(width: gutter, alignment: .leading)
            .offset(y: -10)
    }

    @ViewBuilder
    private var nowLine: some View {
        let minute = calendar.minuteOfDay(of: now)
        if minute >= GymSchedule.openingMinute && minute <= GymSchedule.closingMinute {
            HStack(alignment: .center, spacing: 0) {
                Text(DateText.timeOfDay(minute))
                    .font(Theme.heading(17))
                    .foregroundStyle(Theme.coral)
                    .frame(width: gutter, alignment: .leading)
                Rectangle().fill(Theme.coral).frame(height: 2).padding(.trailing, 16)
            }
            .padding(.top, y(minute: minute) - 11)
        }
    }

    private func anchor(_ hour: Int) -> String { "hour-\(hour)" }

    private func y(minute: Int) -> CGFloat {
        CGFloat(minute - GymSchedule.openingMinute) / 60 * hourHeight
    }
}

private struct DaySessionCard: View {
    let group: SessionGroup
    let now: Date
    let calendar: Calendar

    var body: some View {
        let past = group.state(at: now, calendar: calendar) == .completed
        Group {
            if past { pastContent } else { pendingContent }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(past ? Color.clear : Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(past ? Theme.line : .clear, lineWidth: 1))
        .contentShape(Rectangle())
    }

    private var pastContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark").font(.system(size: 15, weight: .semibold))
            Text(group.clientNames.joined(separator: " · "))
                .font(Theme.body(19))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(Theme.textSecondary)
    }

    private var pendingContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Circle()
                    .fill(group.kind == .individual ? Theme.lime : Theme.cyan)
                    .frame(width: 10, height: 10)
                Text(group.clientNames.joined(separator: " · "))
                    .font(Theme.body(20, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(group.routineNames.joined(separator: " · "))
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                annotation
            }
            .padding(.leading, 20)
        }
    }

    @ViewBuilder
    private var annotation: some View {
        if group.kind == .sharedOpen {
            Text(String(localized: "1 cupo libre"))
                .font(Theme.body(17))
                .foregroundStyle(Theme.cyan)
        } else if let original = group.originalStartsAt {
            Text(String(localized: "Movida desde \(DateText.shortDay(original, calendar: calendar))"))
                .font(Theme.body(17))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
