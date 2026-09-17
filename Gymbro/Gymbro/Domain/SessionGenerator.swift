import Foundation

/// A weekly slot reduced to what generation needs.
nonisolated struct SlotSpec: Hashable {
    var slotID: UUID
    var weekday: Weekday
    var startMinuteOfDay: Int
}

/// A class that should exist in a period, before it is persisted.
nonisolated struct PlannedSession: Equatable {
    var slotID: UUID
    /// 0-based week inside the period.
    var weekIndex: Int
    var startsAt: Date
}

/// Expands weekly slots into concrete class times for the weeks of a period.
nonisolated enum SessionGenerator {
    static func plan(
        slots: [SlotSpec],
        periodStart: Date,
        weekCount: Int = GymSchedule.periodWeekCount,
        calendar: Calendar = .gymbro()
    ) -> [PlannedSession] {
        let weeks = calendar.weeks(from: periodStart, count: weekCount)
        var planned: [PlannedSession] = []
        for (weekIndex, week) in weeks.enumerated() {
            for slot in slots {
                guard let startsAt = calendar.date(
                    weekStart: week.start, weekday: slot.weekday, minuteOfDay: slot.startMinuteOfDay
                ) else { continue }
                planned.append(PlannedSession(slotID: slot.slotID, weekIndex: weekIndex, startsAt: startsAt))
            }
        }
        return planned.sorted { $0.startsAt < $1.startsAt }
    }
}
