import Foundation
import SwiftData

/// Creates plan periods and keeps their classes in sync with the client's weekly slots.
struct PlanRenewalService {
    let context: ModelContext
    let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .gymbro()) {
        self.context = context
        self.calendar = calendar
    }

    /// Marks a renewal: creates the period and all of its classes. If any class cannot be placed,
    /// nothing is saved and every conflict is reported.
    @discardableResult
    func renew(client: Client, classCount: Int, planType: PlanType, on renewalDate: Date) throws -> PlanPeriod {
        guard PlanPeriodRules.isValidClassCount(classCount) else {
            throw SchedulingError.invalidClassCount(classCount)
        }
        let slots = client.sortedWeeklySlots
        let expectedSlots = PlanPeriodRules.classesPerWeek(for: classCount)
        guard slots.count == expectedSlots else {
            throw SchedulingError.slotCountMismatch(expected: expectedSlots, actual: slots.count)
        }
        if let invalid = slots.first(where: { !$0.hasValidTime }) {
            throw SchedulingError.invalidSlotTime(weekday: invalid.weekday, startMinuteOfDay: invalid.startMinuteOfDay)
        }

        let startDate = PlanPeriodRules.startDate(
            forRenewalOn: renewalDate,
            existingPeriods: client.planPeriods.map(\.interval),
            calendar: calendar
        )
        let endDate = PlanPeriodRules.endDate(for: startDate, calendar: calendar)
        let planned = SessionGenerator.plan(slots: slots.map(\.spec), periodStart: startDate, calendar: calendar)

        let repository = BookingRepository(context: context, calendar: calendar)
        var bookings = try repository.bookings(overlapping: DateInterval(start: startDate, end: endDate))
        var conflicts: [SlotConflict] = []
        var sessionIDs: [UUID] = []
        for session in planned {
            let sessionID = UUID()
            let request = PlacementRequest(
                clientID: client.id, planType: planType, startsAt: session.startsAt, hasActivePlan: true
            )
            let result = CapacityRule.evaluate(request, existing: bookings, calendar: calendar)
            if result.isAllowed {
                bookings.append(Booking(
                    sessionID: sessionID, clientID: client.id, planType: planType, startsAt: session.startsAt
                ))
                sessionIDs.append(sessionID)
            } else {
                conflicts.append(SlotConflict(slotID: session.slotID, startsAt: session.startsAt, failure: result.failure!))
            }
        }
        guard conflicts.isEmpty else { throw SchedulingError.conflicts(conflicts) }

        let period = PlanPeriod(startDate: startDate, endDate: endDate, classCount: classCount, planType: planType)
        context.insert(period)
        period.client = client
        client.planType = planType
        for (session, sessionID) in zip(planned, sessionIDs) {
            let slot = slots.first { $0.id == session.slotID }
            let classSession = ClassSession(
                id: sessionID,
                startsAt: session.startsAt,
                routine: slot?.routine,
                weekIndex: session.weekIndex
            )
            context.insert(classSession)
            classSession.client = client
            classSession.planPeriod = period
            classSession.sourceSlot = slot
        }
        return period
    }

    /// Re-aligns the period's classes with the client's current weekly slots. Idempotent: running
    /// it twice creates nothing new. Only future classes that were not rescheduled by hand are
    /// touched. If any change cannot be placed, nothing is changed and the conflicts are reported.
    func syncSessions(for period: PlanPeriod, now: Date) throws {
        guard let client = period.client else { throw SchedulingError.missingPlanPeriod }
        let slots = client.sortedWeeklySlots
        let planned = SessionGenerator.plan(slots: slots.map(\.spec), periodStart: period.startDate, calendar: calendar)

        let repository = BookingRepository(context: context, calendar: calendar)
        var bookings = try repository.bookings(overlapping: period.interval)
        var conflicts: [SlotConflict] = []
        var moves: [(session: ClassSession, startsAt: Date)] = []
        var creations: [(planned: PlannedSession, slot: WeeklySlot)] = []

        for item in planned {
            guard let slot = slots.first(where: { $0.id == item.slotID }) else { continue }
            let request = PlacementRequest(
                clientID: client.id, planType: period.planType, startsAt: item.startsAt, hasActivePlan: true
            )
            if let existing = period.sessions.first(where: {
                $0.sourceSlot?.id == item.slotID && $0.weekIndex == item.weekIndex
            }) {
                guard !existing.isRescheduled, existing.status == .scheduled, existing.startsAt >= now else { continue }
                guard !calendar.isSameMinute(existing.startsAt, item.startsAt) else { continue }
                let result = CapacityRule.evaluate(request, existing: bookings, ignoring: existing.id, calendar: calendar)
                if result.isAllowed {
                    moves.append((existing, item.startsAt))
                    bookings.removeAll { $0.sessionID == existing.id }
                    bookings.append(Booking(
                        sessionID: existing.id, clientID: client.id, planType: period.planType, startsAt: item.startsAt
                    ))
                } else {
                    conflicts.append(SlotConflict(slotID: item.slotID, startsAt: item.startsAt, failure: result.failure!))
                }
            } else {
                guard item.startsAt >= now else { continue }
                let result = CapacityRule.evaluate(request, existing: bookings, calendar: calendar)
                if result.isAllowed {
                    creations.append((item, slot))
                    bookings.append(Booking(
                        sessionID: UUID(), clientID: client.id, planType: period.planType, startsAt: item.startsAt
                    ))
                } else {
                    conflicts.append(SlotConflict(slotID: item.slotID, startsAt: item.startsAt, failure: result.failure!))
                }
            }
        }
        guard conflicts.isEmpty else { throw SchedulingError.conflicts(conflicts) }

        for move in moves {
            move.session.startsAt = move.startsAt
            move.session.routine = move.session.sourceSlot?.routine
        }
        for creation in creations {
            let classSession = ClassSession(
                startsAt: creation.planned.startsAt,
                routine: creation.slot.routine,
                weekIndex: creation.planned.weekIndex
            )
            context.insert(classSession)
            classSession.client = client
            classSession.planPeriod = period
            classSession.sourceSlot = creation.slot
        }
    }
}
