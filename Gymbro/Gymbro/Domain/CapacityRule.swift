import Foundation

/// A class already on the calendar, reduced to what the capacity rule needs.
nonisolated struct Booking: Hashable {
    var sessionID: UUID
    var clientID: UUID
    var planType: PlanType
    var startsAt: Date
}

/// A client asking to occupy a time slot.
nonisolated struct PlacementRequest {
    var clientID: UUID
    var planType: PlanType
    var startsAt: Date
    /// Whether the client has a plan period that contains `startsAt`.
    var hasActivePlan: Bool
}

nonisolated enum PlacementFailure: Equatable {
    /// Start minute is not on the hour or the half hour.
    case invalidStartMinute
    /// Starts before opening or would end after closing.
    case outsideGymHours
    /// Falls on a day the trainer does not work.
    case outsideWorkingDays
    /// The client has no plan period covering that date.
    case noActivePlan
    /// The same client already has a class that overlaps.
    case sameClientOverlap
    /// An overlapping class belongs to an individual client.
    case blockedByIndividual
    /// The requesting client is individual and the slot is not empty.
    case individualCannotShare
    /// Shared slot already has the maximum number of clients.
    case sharedFull
    /// Shared classes overlap without starting at the same time (policy `sameStartOnly`).
    case sharedPartialOverlap
}

nonisolated enum PlacementResult: Equatable {
    /// The slot can be taken. `sharingWith` lists the clients already in it.
    case allowed(sharingWith: [UUID])
    case rejected(PlacementFailure)

    var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }

    var failure: PlacementFailure? {
        if case .rejected(let failure) = self { return failure }
        return nil
    }
}

/// The single rule that decides whether a client can occupy a time slot. Used for weekly slots,
/// rescheduling and period generation alike.
nonisolated enum CapacityRule {
    static func evaluate(
        _ request: PlacementRequest,
        existing: [Booking],
        ignoring ignoredSessionID: UUID? = nil,
        calendar: Calendar = .gymbro()
    ) -> PlacementResult {
        let minute = calendar.minuteOfDay(of: request.startsAt)
        guard GymSchedule.isOnStep(minute) else { return .rejected(.invalidStartMinute) }
        guard GymSchedule.isWithinOpeningHours(minute) else { return .rejected(.outsideGymHours) }
        guard GymSchedule.workingWeekdays.contains(calendar.weekday(of: request.startsAt)) else {
            return .rejected(.outsideWorkingDays)
        }
        guard request.hasActivePlan else { return .rejected(.noActivePlan) }

        let overlapping = existing.filter {
            $0.sessionID != ignoredSessionID && calendar.sessionsOverlap($0.startsAt, request.startsAt)
        }
        guard !overlapping.isEmpty else { return .allowed(sharingWith: []) }

        if overlapping.contains(where: { $0.clientID == request.clientID }) {
            return .rejected(.sameClientOverlap)
        }
        if overlapping.contains(where: { $0.planType == .individual }) {
            return .rejected(.blockedByIndividual)
        }
        if request.planType == .individual {
            return .rejected(.individualCannotShare)
        }
        return sharedPlacement(for: request, overlapping: overlapping, calendar: calendar)
    }

    /// Case isolated on purpose: this is the only place that knows how shared clients overlap.
    private static func sharedPlacement(
        for request: PlacementRequest,
        overlapping: [Booking],
        calendar: Calendar
    ) -> PlacementResult {
        switch GymSchedule.sharedOverlapPolicy {
        case .sameStartOnly:
            let sameStart = overlapping.filter { calendar.isSameMinute($0.startsAt, request.startsAt) }
            guard sameStart.count == overlapping.count else { return .rejected(.sharedPartialOverlap) }
            guard sameStart.count < GymSchedule.maxSharedClientsPerSlot else { return .rejected(.sharedFull) }
            return .allowed(sharingWith: sameStart.map(\.clientID))

        case .halfBlocks:
            let halfLength = TimeInterval(GymSchedule.startStepMinutes * 60)
            let halfStarts = [request.startsAt, request.startsAt.addingTimeInterval(halfLength)]
            for halfStart in halfStarts {
                let occupants = overlapping.filter { booking in
                    let end = calendar.sessionEnd(startingAt: booking.startsAt)
                    return booking.startsAt <= halfStart && halfStart < end
                }
                if occupants.count >= GymSchedule.maxSharedClientsPerSlot {
                    return .rejected(.sharedFull)
                }
            }
            let clients = Array(Set(overlapping.map(\.clientID)))
            return .allowed(sharingWith: clients)
        }
    }
}
