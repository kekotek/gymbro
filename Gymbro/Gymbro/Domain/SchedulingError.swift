import Foundation

/// A planned class that could not be placed.
nonisolated struct SlotConflict: Equatable {
    var slotID: UUID
    var startsAt: Date
    var failure: PlacementFailure
}

nonisolated enum SchedulingError: Error, Equatable {
    case invalidClassCount(Int)
    case slotCountMismatch(expected: Int, actual: Int)
    case invalidSlotTime(weekday: Weekday, startMinuteOfDay: Int)
    /// Nothing was saved; every conflicting class is listed so the trainer can resolve them.
    case conflicts([SlotConflict])
    case placementRejected(PlacementFailure)
    case sessionNotScheduled
    case missingPlanPeriod
    case targetOutsidePlanPeriod
}
