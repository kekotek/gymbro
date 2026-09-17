import SwiftUI

/// Seven-column grid of the week, one block per class, colored by plan type and occupancy.
struct WeekCalendarView: View {
    let week: DateInterval
    let sessions: [ClassSession]
    let now: Date
    let calendar: Calendar
    let onSelectDay: (Date) -> Void

    private let hourHeight: CGFloat = 54
    private let gutter: CGFloat = 36
    private var hours: [Int] { Array((GymSchedule.openingMinute / 60)...(GymSchedule.closingMinute / 60)) }
    private var gridHeight: CGFloat { CGFloat(hours.count - 1) * hourHeight }

    var body: some View {
        let groups = SessionGroup.groups(from: sessions, calendar: calendar)
        VStack(spacing: 10) {
            legend
                .padding(.horizontal, 20)
            WeekdayStrip(week: week, highlightedDate: now, calendar: calendar, leadingInset: gutter, onSelect: onSelectDay)
                .padding(.trailing, 8)
            ScrollView(showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    timeGutter
                    ForEach(0..<7, id: \.self) { offset in
                        let day = calendar.date(byAdding: .day, value: offset, to: week.start)!
                        column(for: day, groups: groups.filter { calendar.isDate($0.startsAt, inSameDayAs: day) })
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 96)
                .padding(.trailing, 8)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(String(localized: "Individual"), fill: Theme.lime)
            legendItem(String(localized: "Compartido"), fill: Theme.cyan)
            HStack(spacing: 6) {
                Circle().strokeBorder(Theme.cyan, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2])).frame(width: 12, height: 12)
                Text(String(localized: "Con 1 cupo"))
            }
            Spacer()
        }
        .font(Theme.body(15))
        .foregroundStyle(Theme.textSecondary)
    }

    private func legendItem(_ title: String, fill: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(fill).frame(width: 12, height: 12)
            Text(title)
        }
    }

    private var timeGutter: some View {
        ZStack(alignment: .topLeading) {
            ForEach(hours, id: \.self) { hour in
                Text(String(format: "%02d", hour))
                    .font(Theme.heading(15))
                    .foregroundStyle(Theme.textSecondary)
                    .offset(y: y(minute: hour * 60) - 9)
            }
        }
        .frame(width: gutter, height: gridHeight, alignment: .topLeading)
    }

    private func column(for day: Date, groups: [SessionGroup]) -> some View {
        ZStack(alignment: .top) {
            if calendar.isDate(day, inSameDayAs: now) {
                Theme.surface.opacity(0.55)
            }
            ForEach(hours, id: \.self) { hour in
                Rectangle()
                    .fill(Theme.line)
                    .frame(height: 1)
                    .offset(y: y(minute: hour * 60))
            }
            ForEach(groups) { group in
                NavigationLink(value: group.sessions[0]) {
                    WeekBlock(group: group, now: now, calendar: calendar)
                }
                .buttonStyle(.plain)
                .frame(height: hourHeight - 4)
                .padding(.horizontal, 2)
                .offset(y: y(minute: calendar.minuteOfDay(of: group.startsAt)) + 2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: gridHeight, alignment: .top)
    }

    private func y(minute: Int) -> CGFloat {
        CGFloat(minute - GymSchedule.openingMinute) / 60 * hourHeight
    }
}

private struct WeekBlock: View {
    let group: SessionGroup
    let now: Date
    let calendar: Calendar

    var body: some View {
        let past = group.state(at: now, calendar: calendar) == .completed
        let style = BlockStyle(kind: group.kind, past: past)
        VStack(spacing: -2) {
            ForEach(Array(group.initials.enumerated()), id: \.offset) { item in
                Text(item.element)
            }
        }
        .font(Theme.heading(16))
        .foregroundStyle(style.foreground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 8).fill(style.fill))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style.stroke, style: StrokeStyle(lineWidth: 1.5, dash: style.dashed ? [3, 3] : []))
        )
        .contentShape(Rectangle())
    }
}

private struct BlockStyle {
    let fill: Color
    let stroke: Color
    let foreground: Color
    let dashed: Bool

    init(kind: SessionGroup.Kind, past: Bool) {
        switch kind {
        case .individual:
            fill = past ? Theme.lime.opacity(0.28) : Theme.lime
            stroke = .clear
            foreground = past ? Theme.textPrimary.opacity(0.75) : Theme.onLime
            dashed = false
        case .sharedFull:
            fill = past ? Theme.cyan.opacity(0.22) : Theme.cyan
            stroke = .clear
            foreground = past ? Theme.textPrimary.opacity(0.75) : Theme.onCyan
            dashed = false
        case .sharedOpen:
            fill = past ? .clear : Theme.surface
            stroke = past ? Theme.cyan.opacity(0.4) : Theme.cyan
            foreground = past ? Theme.cyan.opacity(0.5) : Theme.cyan
            dashed = true
        }
    }
}
