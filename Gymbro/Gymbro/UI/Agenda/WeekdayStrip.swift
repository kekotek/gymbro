import SwiftUI

/// Row with the seven days of the week (L M X J V S D) and their day numbers.
struct WeekdayStrip: View {
    let week: DateInterval
    let highlightedDate: Date
    let calendar: Calendar
    /// Space reserved on the left to align with the calendar's time gutter.
    var leadingInset: CGFloat = 0
    let onSelect: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: leadingInset, height: 1)
            ForEach(0..<7, id: \.self) { offset in
                let day = calendar.date(byAdding: .day, value: offset, to: week.start)!
                let highlighted = calendar.isDate(day, inSameDayAs: highlightedDate)
                Button { onSelect(day) } label: {
                    VStack(spacing: 4) {
                        Text(DateText.weekdayLetters[calendar.weekday(of: day)] ?? "")
                            .font(Theme.body(13, weight: .medium))
                            .foregroundStyle(highlighted ? Theme.onLime : Theme.textSecondary)
                        Text("\(DateText.day(day, calendar: calendar))")
                            .font(Theme.heading(22))
                            .foregroundStyle(highlighted ? Theme.onLime : Theme.textPrimary)
                    }
                    .frame(width: 42, height: 54)
                    .background(RoundedRectangle(cornerRadius: 12).fill(highlighted ? Theme.lime : .clear))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
