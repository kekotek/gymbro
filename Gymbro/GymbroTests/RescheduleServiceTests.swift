import Foundation
import SwiftData
import Testing
@testable import Gymbro

/// Scenario from the reference screens: Francisca (shared, Thu 09:00) moves her class of Thu 17
/// to Fri 18 07:00, where Valentina (shared) already trains.
@Suite struct RescheduleServiceTests {
    let calendar = TestSupport.calendar
    let now = TestSupport.now

    struct Scenario {
        let context: ModelContext
        let francisca: Client
        let valentina: Client
        let session: ClassSession
        let renewal: PlanRenewalService
        let reschedule: RescheduleService
    }

    func makeScenario() throws -> Scenario {
        let context = try TestSupport.makeContext()
        let francisca = TestSupport.makeClient("Francisca", planType: .shared, slots: [(.thursday, 540)], in: context)
        let valentina = TestSupport.makeClient("Valentina", planType: .shared, slots: [(.friday, 420)], in: context)
        let renewal = PlanRenewalService(context: context, calendar: calendar)
        let period = try renewal.renew(client: francisca, classCount: 4, planType: .shared, on: now)
        try renewal.renew(client: valentina, classCount: 4, planType: .shared, on: now)
        let session = try #require(period.sessions.first { $0.startsAt == TestSupport.date(2026, 9, 17, 9, 0) })
        return Scenario(
            context: context, francisca: francisca, valentina: valentina, session: session,
            renewal: renewal, reschedule: RescheduleService(context: context, calendar: calendar)
        )
    }

    @Test func moveIntoSharedSlotWithRoom() throws {
        let scenario = try makeScenario()
        let target = TestSupport.date(2026, 9, 18, 7, 0)

        #expect(try scenario.reschedule.evaluate(scenario.session, movingTo: target) == .allowed(sharingWith: [scenario.valentina.id]))
        try scenario.reschedule.reschedule(scenario.session, to: target, scope: .thisClassOnly)

        #expect(scenario.session.startsAt == target)
        #expect(scenario.session.originalStartsAt == TestSupport.date(2026, 9, 17, 9, 0))
        #expect(scenario.session.isRescheduled)
        #expect(scenario.francisca.weeklySlots.first?.weekday == .thursday)
        #expect(scenario.francisca.sessions.filter { $0.startsAt == TestSupport.date(2026, 9, 24, 9, 0) }.count == 1)
    }

    @Test func halfOverlapWithSharedClassIsRejected() throws {
        let scenario = try makeScenario()
        for minute in [(6, 30), (7, 30)] {
            let target = TestSupport.date(2026, 9, 18, minute.0, minute.1)
            #expect(throws: SchedulingError.placementRejected(.sharedPartialOverlap)) {
                try scenario.reschedule.reschedule(scenario.session, to: target, scope: .thisClassOnly)
            }
        }
        #expect(scenario.session.startsAt == TestSupport.date(2026, 9, 17, 9, 0))
    }

    @Test func moveIntoSlotTakenByIndividualIsRejected() throws {
        let scenario = try makeScenario()
        let tomas = TestSupport.makeClient("Tomás", planType: .individual, slots: [(.friday, 480)], in: scenario.context)
        try scenario.renewal.renew(client: tomas, classCount: 4, planType: .individual, on: now)

        #expect(throws: SchedulingError.placementRejected(.blockedByIndividual)) {
            try scenario.reschedule.reschedule(scenario.session, to: TestSupport.date(2026, 9, 18, 8, 0), scope: .thisClassOnly)
        }
    }

    @Test func moveIntoFullSharedSlotIsRejected() throws {
        let scenario = try makeScenario()
        let camila = TestSupport.makeClient("Camila", planType: .shared, slots: [(.friday, 420)], in: scenario.context)
        try scenario.renewal.renew(client: camila, classCount: 4, planType: .shared, on: now)

        #expect(throws: SchedulingError.placementRejected(.sharedFull)) {
            try scenario.reschedule.reschedule(scenario.session, to: TestSupport.date(2026, 9, 18, 7, 0), scope: .thisClassOnly)
        }
    }

    @Test func classDoesNotBlockItself() throws {
        let scenario = try makeScenario()
        let sameTime = TestSupport.date(2026, 9, 17, 9, 0)
        #expect(try scenario.reschedule.evaluate(scenario.session, movingTo: sameTime).isAllowed)
        #expect(try scenario.reschedule.evaluate(scenario.session, movingTo: TestSupport.date(2026, 9, 17, 9, 30)).isAllowed)
        try scenario.reschedule.reschedule(scenario.session, to: TestSupport.date(2026, 9, 17, 9, 30), scope: .thisClassOnly)
        #expect(scenario.session.startsAt == TestSupport.date(2026, 9, 17, 9, 30))
    }

    @Test func moveOutsidePlanPeriodIsRejected() throws {
        let scenario = try makeScenario()
        #expect(throws: SchedulingError.targetOutsidePlanPeriod) {
            try scenario.reschedule.reschedule(scenario.session, to: TestSupport.date(2026, 10, 15, 9, 0), scope: .thisClassOnly)
        }
        #expect(throws: SchedulingError.targetOutsidePlanPeriod) {
            try scenario.reschedule.reschedule(scenario.session, to: TestSupport.date(2026, 9, 10, 9, 0), scope: .thisClassOnly)
        }
    }

    @Test func moveToAnotherWeekInsidePeriodIsAllowed() throws {
        let scenario = try makeScenario()
        let target = TestSupport.date(2026, 9, 22, 12, 0)
        try scenario.reschedule.reschedule(scenario.session, to: target, scope: .thisClassOnly)
        #expect(scenario.session.startsAt == target)
    }

    @Test func cancelledOrCompletedClassCannotBeRescheduled() throws {
        let scenario = try makeScenario()
        scenario.session.cancel()
        #expect(throws: SchedulingError.sessionNotScheduled) {
            try scenario.reschedule.reschedule(scenario.session, to: TestSupport.date(2026, 9, 18, 7, 0), scope: .thisClassOnly)
        }
    }

    @Test func cancelledClassFreesItsSlot() throws {
        let scenario = try makeScenario()
        let valentinaFriday = try #require(scenario.valentina.sessions.first { $0.startsAt == TestSupport.date(2026, 9, 18, 7, 0) })
        valentinaFriday.cancel()
        #expect(try scenario.reschedule.evaluate(scenario.session, movingTo: valentinaFriday.startsAt) == .allowed(sharingWith: []))
    }

    @Test func fromNowOnMovesSlotAndLaterClasses() throws {
        let scenario = try makeScenario()
        let target = TestSupport.date(2026, 9, 18, 7, 0)

        try scenario.reschedule.reschedule(scenario.session, to: target, scope: .fromNowOn)

        let slot = try #require(scenario.francisca.weeklySlots.first)
        #expect(slot.weekday == .friday)
        #expect(slot.startMinuteOfDay == 420)
        let starts = scenario.francisca.sessions.map(\.startsAt).sorted()
        #expect(starts == [
            TestSupport.date(2026, 9, 18, 7, 0), TestSupport.date(2026, 9, 25, 7, 0),
            TestSupport.date(2026, 10, 2, 7, 0), TestSupport.date(2026, 10, 9, 7, 0),
        ])
        #expect(scenario.session.isRescheduled)
        #expect(scenario.francisca.sessions.filter(\.isRescheduled).count == 1)
    }

    @Test func fromNowOnLeavesEarlierClassesAlone() throws {
        let scenario = try makeScenario()
        let later = try #require(scenario.francisca.sessions.first { $0.startsAt == TestSupport.date(2026, 9, 24, 9, 0) })

        try scenario.reschedule.reschedule(later, to: TestSupport.date(2026, 9, 25, 7, 0), scope: .fromNowOn)

        #expect(scenario.session.startsAt == TestSupport.date(2026, 9, 17, 9, 0))
        let starts = scenario.francisca.sessions.map(\.startsAt).sorted()
        #expect(starts == [
            TestSupport.date(2026, 9, 17, 9, 0), TestSupport.date(2026, 9, 25, 7, 0),
            TestSupport.date(2026, 10, 2, 7, 0), TestSupport.date(2026, 10, 9, 7, 0),
        ])
    }

    @Test func fromNowOnAbortsWhenALaterWeekIsTaken() throws {
        let scenario = try makeScenario()
        let blocker = TestSupport.makeClient("Tomás", planType: .individual, slots: [(.friday, 480)], in: scenario.context)
        try scenario.renewal.renew(client: blocker, classCount: 4, planType: .individual, on: now)
        // Free only this week's Friday 08:00 so the first move is fine but the later ones collide.
        let thisWeek = try #require(blocker.sessions.first { $0.startsAt == TestSupport.date(2026, 9, 18, 8, 0) })
        thisWeek.cancel()

        let error = #expect(throws: SchedulingError.self) {
            try scenario.reschedule.reschedule(scenario.session, to: TestSupport.date(2026, 9, 18, 8, 0), scope: .fromNowOn)
        }
        guard case .conflicts(let conflicts)? = error else {
            Issue.record("expected conflicts, got \(String(describing: error))")
            return
        }
        #expect(conflicts.count == 3)
        #expect(scenario.session.startsAt == TestSupport.date(2026, 9, 17, 9, 0))
        #expect(scenario.francisca.weeklySlots.first?.weekday == .thursday)
    }
}
