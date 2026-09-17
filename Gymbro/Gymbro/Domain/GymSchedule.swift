import Foundation

/// Fixed scheduling parameters of the gym. Everything that is an assumption lives here so it is
/// easy to change in one place.
nonisolated enum GymSchedule {
    /// Gym opens at 06:00.
    static let openingMinute = 6 * 60
    /// Gym closes at 22:00.
    static let closingMinute = 22 * 60
    /// Every class lasts one hour.
    static let sessionDurationMinutes = 60
    /// Classes may start on the hour or at the half hour.
    static let startStepMinutes = 30
    /// Latest possible start so the class ends within opening hours (21:00).
    static var latestStartMinute: Int { closingMinute - sessionDurationMinutes }

    /// Assumption (open question 1): the trainer works Monday to Saturday.
    /// The reference reschedule screen skips Sunday and the week view has a Saturday class.
    static let workingWeekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    /// A plan period always covers four weeks.
    static let periodWeekCount = 4
    /// The calendar shows the current week plus the next four.
    static let visibleWeekCount = 5
    /// Valid monthly class counts.
    static let allowedClassCounts: Set<Int> = [4, 8, 12, 16]

    /// How many shared clients fit in one slot.
    static let maxSharedClientsPerSlot = 2
    /// Assumption (open question 3): shared clients only share when they start at the same time.
    static let sharedOverlapPolicy: SharedOverlapPolicy = .sameStartOnly

    /// Whether a minute-of-day is a valid class start (on the step and within opening hours).
    static func isValidStartMinute(_ minuteOfDay: Int) -> Bool {
        isOnStep(minuteOfDay) && isWithinOpeningHours(minuteOfDay)
    }

    static func isOnStep(_ minuteOfDay: Int) -> Bool {
        minuteOfDay % startStepMinutes == 0
    }

    static func isWithinOpeningHours(_ minuteOfDay: Int) -> Bool {
        minuteOfDay >= openingMinute && minuteOfDay <= latestStartMinute
    }

    /// Every valid start minute of a day, in order (06:00, 06:30 … 21:00).
    static var allStartMinutes: [Int] {
        Array(stride(from: openingMinute, through: latestStartMinute, by: startStepMinutes))
    }
}

/// Rule for two shared clients whose classes overlap without starting at the same time.
nonisolated enum SharedOverlapPolicy {
    /// Shared clients share a slot only if they start at the same time (8:00 + 8:30 is rejected).
    case sameStartOnly
    /// Each 30-minute half block can hold up to `maxSharedClientsPerSlot` shared clients.
    case halfBlocks
}
