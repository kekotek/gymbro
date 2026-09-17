import Foundation
import SwiftData

/// Books a class outside the weekly slots, e.g. adding a second shared client to a slot with room.
struct SessionBookingService {
    let context: ModelContext
    let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .gymbro()) {
        self.context = context
        self.calendar = calendar
    }

    @discardableResult
    func book(client: Client, at startsAt: Date) throws -> ClassSession {
        guard let period = client.activePeriod(on: startsAt) else { throw SchedulingError.missingPlanPeriod }
        let bookings = try BookingRepository(context: context, calendar: calendar).bookings(around: startsAt)
        let request = PlacementRequest(clientID: client.id, planType: period.planType, startsAt: startsAt, hasActivePlan: true)
        let result = CapacityRule.evaluate(request, existing: bookings, calendar: calendar)
        guard result.isAllowed else { throw SchedulingError.placementRejected(result.failure!) }

        let weeks = calendar.weeks(from: period.startDate, count: GymSchedule.periodWeekCount)
        let weekIndex = weeks.firstIndex { $0.start <= startsAt && startsAt < $0.end } ?? 0
        let session = ClassSession(startsAt: startsAt, weekIndex: weekIndex)
        context.insert(session)
        session.client = client
        session.planPeriod = period
        return session
    }
}
