import Foundation
import SwiftData

struct SlotAvailability: Identifiable {
    var startsAt: Date
    var result: PlacementResult
    var id: Date { startsAt }
}

enum RescheduleScope {
    /// Only this class moves; the weekly slot and the other weeks stay as they are.
    case thisClassOnly
    /// The weekly slot changes and the later classes of the same period follow it.
    case fromNowOn
}

/// Moves a class to another time, enforcing the capacity rule and the plan period.
struct RescheduleService {
    let context: ModelContext
    let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .gymbro()) {
        self.context = context
        self.calendar = calendar
    }

    /// Evaluates a candidate start without changing anything (used to paint the time grid).
    func evaluate(_ session: ClassSession, movingTo newStart: Date) throws -> PlacementResult {
        guard let client = session.client, let period = session.planPeriod else {
            throw SchedulingError.missingPlanPeriod
        }
        let bookings = try BookingRepository(context: context, calendar: calendar).bookings(around: newStart)
        let request = PlacementRequest(
            clientID: client.id,
            planType: session.planType,
            startsAt: newStart,
            hasActivePlan: period.contains(newStart)
        )
        return CapacityRule.evaluate(request, existing: bookings, ignoring: session.id, calendar: calendar)
    }

    /// Every possible start on `day`, evaluated for `session`, reading the day's bookings once.
    func availability(for session: ClassSession, on day: Date) throws -> [SlotAvailability] {
        guard let client = session.client, let period = session.planPeriod else {
            throw SchedulingError.missingPlanPeriod
        }
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let bookings = try BookingRepository(context: context, calendar: calendar)
            .bookings(overlapping: DateInterval(start: dayStart, end: dayEnd))
        return GymSchedule.allStartMinutes.compactMap { minute in
            guard let startsAt = calendar.date(day: dayStart, minuteOfDay: minute) else { return nil }
            let request = PlacementRequest(
                clientID: client.id, planType: session.planType, startsAt: startsAt, hasActivePlan: period.contains(startsAt)
            )
            let result = CapacityRule.evaluate(request, existing: bookings, ignoring: session.id, calendar: calendar)
            return SlotAvailability(startsAt: startsAt, result: result)
        }
    }

    func reschedule(_ session: ClassSession, to newStart: Date, scope: RescheduleScope) throws {
        guard session.status == .scheduled else { throw SchedulingError.sessionNotScheduled }
        guard let client = session.client, let period = session.planPeriod else {
            throw SchedulingError.missingPlanPeriod
        }
        // Assumption (open question 6): a class can move to any day of its own plan period.
        guard period.contains(newStart) else { throw SchedulingError.targetOutsidePlanPeriod }

        let result = try evaluate(session, movingTo: newStart)
        guard result.isAllowed else { throw SchedulingError.placementRejected(result.failure!) }

        switch scope {
        case .thisClassOnly:
            session.move(to: newStart)

        case .fromNowOn:
            guard let slot = session.sourceSlot else {
                session.move(to: newStart)
                return
            }
            let newWeekday = calendar.weekday(of: newStart)
            let newMinute = calendar.minuteOfDay(of: newStart)
            let moves = try plannedFollowerMoves(
                of: session, slot: slot, period: period, client: client,
                newWeekday: newWeekday, newMinute: newMinute, newStart: newStart
            )
            session.move(to: newStart)
            slot.weekday = newWeekday
            slot.startMinuteOfDay = newMinute
            for move in moves {
                move.session.startsAt = move.startsAt
            }
        }
    }

    /// Later classes of the same slot and period that still follow the slot. Validated before
    /// anything is changed; any conflict aborts the whole operation.
    private func plannedFollowerMoves(
        of session: ClassSession,
        slot: WeeklySlot,
        period: PlanPeriod,
        client: Client,
        newWeekday: Weekday,
        newMinute: Int,
        newStart: Date
    ) throws -> [(session: ClassSession, startsAt: Date)] {
        let weeks = calendar.weeks(from: period.startDate, count: GymSchedule.periodWeekCount)
        let followers = period.sessions
            .filter {
                $0.id != session.id && $0.sourceSlot?.id == slot.id && $0.startsAt > session.startsAt
                    && !$0.isRescheduled && $0.status == .scheduled
            }
            .sorted { $0.startsAt < $1.startsAt }

        let repository = BookingRepository(context: context, calendar: calendar)
        let movedBooking = Booking(sessionID: session.id, clientID: client.id, planType: session.planType, startsAt: newStart)
        var moves: [(session: ClassSession, startsAt: Date)] = []
        var conflicts: [SlotConflict] = []
        for follower in followers {
            guard follower.weekIndex < weeks.count,
                  let target = calendar.date(
                      weekStart: weeks[follower.weekIndex].start, weekday: newWeekday, minuteOfDay: newMinute
                  ) else { continue }
            var bookings = try repository.bookings(around: target)
            bookings.removeAll { $0.sessionID == session.id }
            bookings.append(movedBooking)
            let request = PlacementRequest(
                clientID: client.id, planType: session.planType, startsAt: target, hasActivePlan: period.contains(target)
            )
            let result = CapacityRule.evaluate(request, existing: bookings, ignoring: follower.id, calendar: calendar)
            if result.isAllowed {
                moves.append((follower, target))
            } else {
                conflicts.append(SlotConflict(slotID: slot.id, startsAt: target, failure: result.failure!))
            }
        }
        guard conflicts.isEmpty else { throw SchedulingError.conflicts(conflicts) }
        return moves
    }
}
