import Foundation
import SwiftData

/// A concrete one-hour class on a specific date. This is what the calendar draws.
@Model
final class ClassSession {
    @Attribute(.unique) var id: UUID
    var client: Client?
    /// Start instant; minute 0 or 30.
    var startsAt: Date
    /// Copied from the weekly slot; travels with the class when rescheduled.
    var routine: Routine?
    /// Period this class is charged to.
    var planPeriod: PlanPeriod?
    /// Weekly slot the class was generated from.
    var sourceSlot: WeeklySlot?
    /// 0-based week inside the plan period.
    var weekIndex: Int
    /// Set only when rescheduled: the start it had before the first move.
    var originalStartsAt: Date?
    var status: SessionStatus

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        startsAt: Date,
        routine: Routine? = nil,
        planPeriod: PlanPeriod? = nil,
        sourceSlot: WeeklySlot? = nil,
        weekIndex: Int,
        originalStartsAt: Date? = nil,
        status: SessionStatus = .scheduled
    ) {
        self.id = id
        self.client = client
        self.startsAt = startsAt
        self.routine = routine
        self.planPeriod = planPeriod
        self.sourceSlot = sourceSlot
        self.weekIndex = weekIndex
        self.originalStartsAt = originalStartsAt
        self.status = status
    }

    /// Plan type in force for this class.
    var planType: PlanType {
        planPeriod?.planType ?? client?.planType ?? .individual
    }

    var isRescheduled: Bool { originalStartsAt != nil }

    func endsAt(calendar: Calendar = .gymbro()) -> Date {
        calendar.sessionEnd(startingAt: startsAt)
    }

    func state(at now: Date, calendar: Calendar = .gymbro()) -> SessionState {
        SessionState.resolve(status: status, endsAt: endsAt(calendar: calendar), now: now)
    }

    /// What the capacity rule sees. Cancelled classes free their slot.
    var booking: Booking? {
        guard status != .cancelled, let client else { return nil }
        return Booking(sessionID: id, clientID: client.id, planType: planType, startsAt: startsAt)
    }

    /// Moves the class, remembering the original start the first time.
    func move(to newStart: Date) {
        if originalStartsAt == nil { originalStartsAt = startsAt }
        startsAt = newStart
    }

    func markCompleted() { status = .completed }

    func cancel() { status = .cancelled }
}
