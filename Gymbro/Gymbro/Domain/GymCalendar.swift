import Foundation

nonisolated extension Calendar {
    /// Gregorian calendar with Monday as the first day of the week and Chilean locale.
    static func gymbro(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "es_CL")
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    /// Monday 00:00 of the week that contains `date`.
    func startOfWeek(containing date: Date) -> Date {
        dateInterval(of: .weekOfYear, for: date)!.start
    }

    /// The week (Monday 00:00 to next Monday 00:00) that contains `date`.
    func week(containing date: Date) -> DateInterval {
        dateInterval(of: .weekOfYear, for: date)!
    }

    /// Consecutive week intervals starting with the week that contains `date`.
    func weeks(from date: Date, count: Int) -> [DateInterval] {
        let first = startOfWeek(containing: date)
        return (0..<count).compactMap { index in
            guard let start = self.date(byAdding: .weekOfYear, value: index, to: first) else { return nil }
            return week(containing: start)
        }
    }

    func weekday(of date: Date) -> Weekday {
        Weekday(calendarComponent: component(.weekday, from: date))
    }

    /// Minutes since midnight, local time.
    func minuteOfDay(of date: Date) -> Int {
        let parts = dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// Builds the instant for `weekday` at `minuteOfDay` inside the week that starts on `weekStart`.
    func date(weekStart: Date, weekday: Weekday, minuteOfDay: Int) -> Date? {
        guard let day = date(byAdding: .day, value: weekday.rawValue - 1, to: weekStart) else { return nil }
        return date(bySettingHour: minuteOfDay / 60, minute: minuteOfDay % 60, second: 0, of: day)
    }

    /// End of a class that starts at `startsAt`.
    func sessionEnd(startingAt startsAt: Date) -> Date {
        date(byAdding: .minute, value: GymSchedule.sessionDurationMinutes, to: startsAt)!
    }

    /// True when two one-hour classes overlap in time.
    func sessionsOverlap(_ a: Date, _ b: Date) -> Bool {
        abs(a.timeIntervalSince(b)) < TimeInterval(GymSchedule.sessionDurationMinutes * 60)
    }

    /// True when both instants are the same minute.
    func isSameMinute(_ a: Date, _ b: Date) -> Bool {
        compare(a, to: b, toGranularity: .minute) == .orderedSame
    }
}
