import Foundation

/// Day of the week, Monday-first, matching the app's calendar (lunes a domingo).
nonisolated enum Weekday: Int, CaseIterable, Codable, Comparable, Hashable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    /// Builds a weekday from `Calendar`'s `.weekday` component (1 = Sunday … 7 = Saturday).
    init(calendarComponent: Int) {
        let raw = ((calendarComponent + 5) % 7) + 1
        self = Weekday(rawValue: raw)!
    }

    /// The value `Calendar` uses for this day in its `.weekday` component.
    var calendarComponent: Int { (rawValue % 7) + 1 }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }
}
