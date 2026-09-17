import Foundation

/// Rules for the monthly renewal (plan period).
nonisolated enum PlanPeriodRules {
    static func isValidClassCount(_ classCount: Int) -> Bool {
        GymSchedule.allowedClassCounts.contains(classCount)
    }

    /// Assumption: monthly classes are spread evenly (4, 8, 12, 16 → 1, 2, 3, 4 per week).
    static func classesPerWeek(for classCount: Int) -> Int {
        classCount / GymSchedule.periodWeekCount
    }

    /// Assumption (open question 4): a period starts on a Monday. If the client has a period that
    /// still runs past the Monday of the renewal week, the new period starts right after it
    /// (the reference renewal screen shows "lun 12 oct" for a plan ending "dom 11 oct").
    /// Otherwise it starts on the Monday of the week in which the renewal is made.
    static func startDate(
        forRenewalOn renewalDate: Date,
        existingPeriods: [DateInterval],
        calendar: Calendar = .gymbro()
    ) -> Date {
        let weekStart = calendar.startOfWeek(containing: renewalDate)
        if let latestEnd = existingPeriods.map(\.end).max(), latestEnd > weekStart {
            return latestEnd
        }
        return weekStart
    }

    /// Exclusive end: the Monday four weeks after `startDate`.
    static func endDate(for startDate: Date, calendar: Calendar = .gymbro()) -> Date {
        calendar.date(byAdding: .weekOfYear, value: GymSchedule.periodWeekCount, to: startDate)!
    }
}
