import Foundation
import SwiftData
import Testing
@testable import Gymbro

@Suite struct PlanRenewalServiceTests {
    let calendar = TestSupport.calendar
    let now = TestSupport.now

    @Test(arguments: [4, 8, 12, 16])
    func renewalGeneratesExactlyTheClassCount(classCount: Int) throws {
        let context = try TestSupport.makeContext()
        let allSlots: [(Weekday, Int)] = [(.monday, 600), (.tuesday, 540), (.thursday, 540), (.friday, 720)]
        let client = TestSupport.makeClient("A", planType: .individual, slots: Array(allSlots.prefix(classCount / 4)), in: context)

        let period = try PlanRenewalService(context: context, calendar: calendar)
            .renew(client: client, classCount: classCount, planType: .individual, on: now)

        #expect(period.sessions.count == classCount)
        #expect(client.sessions.count == classCount)
        #expect(period.startDate == TestSupport.date(2026, 9, 14))
        #expect(period.endDate == TestSupport.date(2026, 10, 12))
        #expect(period.sessions.allSatisfy { $0.planPeriod?.id == period.id && $0.sourceSlot != nil })
        #expect(client.activePeriod(on: now)?.id == period.id)
    }

    @Test func invalidClassCountIsRejected() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        #expect(throws: SchedulingError.invalidClassCount(10)) {
            try service.renew(client: client, classCount: 10, planType: .individual, on: now)
        }
        #expect(client.planPeriods.isEmpty)
        #expect(client.sessions.isEmpty)
    }

    @Test func slotCountMustMatchClassesPerWeek() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        #expect(throws: SchedulingError.slotCountMismatch(expected: 2, actual: 1)) {
            try service.renew(client: client, classCount: 8, planType: .individual, on: now)
        }
        #expect(client.sessions.isEmpty)
    }

    @Test func slotOutsideGymHoursIsRejected() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 1290)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        #expect(throws: SchedulingError.invalidSlotTime(weekday: .monday, startMinuteOfDay: 1290)) {
            try service.renew(client: client, classCount: 4, planType: .individual, on: now)
        }
    }

    @Test func clientWithoutRenewalHasNoClasses() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600)], in: context)
        #expect(client.sessions.isEmpty)
        #expect(client.activePeriod(on: now) == nil)
        let sessions = try context.fetch(FetchDescriptor<ClassSession>())
        #expect(sessions.isEmpty)
    }

    @Test func earlyRenewalStartsAfterCurrentPeriodAndClassesFollow() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .shared, slots: [(.thursday, 540)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        try service.renew(client: client, classCount: 4, planType: .shared, on: now)
        let next = try service.renew(client: client, classCount: 4, planType: .shared, on: now)

        #expect(next.startDate == TestSupport.date(2026, 10, 12))
        #expect(next.endDate == TestSupport.date(2026, 11, 9))
        #expect(next.sessions.map(\.startsAt).sorted().first == TestSupport.date(2026, 10, 15, 9, 0))
        #expect(client.sessions.count == 8)
    }

    @Test func conflictingSlotSavesNothingAndReportsEveryWeek() throws {
        let context = try TestSupport.makeContext()
        let first = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600)], in: context)
        let second = TestSupport.makeClient("B", planType: .individual, slots: [(.monday, 600)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        try service.renew(client: first, classCount: 4, planType: .individual, on: now)

        let error = #expect(throws: SchedulingError.self) {
            try service.renew(client: second, classCount: 4, planType: .individual, on: now)
        }
        guard case .conflicts(let conflicts)? = error else {
            Issue.record("expected conflicts, got \(String(describing: error))")
            return
        }
        #expect(conflicts.count == 4)
        #expect(conflicts.allSatisfy { $0.failure == .blockedByIndividual })
        #expect(second.planPeriods.isEmpty)
        #expect(second.sessions.isEmpty)
        #expect(try context.fetch(FetchDescriptor<ClassSession>()).count == 4)
    }

    @Test func twoSharedClientsCanRenewTheSameSlot() throws {
        let context = try TestSupport.makeContext()
        let first = TestSupport.makeClient("A", planType: .shared, slots: [(.monday, 600)], in: context)
        let second = TestSupport.makeClient("B", planType: .shared, slots: [(.monday, 600)], in: context)
        let third = TestSupport.makeClient("C", planType: .shared, slots: [(.monday, 600)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        try service.renew(client: first, classCount: 4, planType: .shared, on: now)
        try service.renew(client: second, classCount: 4, planType: .shared, on: now)
        #expect(throws: SchedulingError.self) {
            try service.renew(client: third, classCount: 4, planType: .shared, on: now)
        }
        #expect(third.sessions.isEmpty)
    }

    @Test func overlappingSlotsOfTheSameClientAreRejected() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600), (.monday, 630)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        #expect(throws: SchedulingError.self) {
            try service.renew(client: client, classCount: 8, planType: .individual, on: now)
        }
        #expect(client.sessions.isEmpty)
    }

    @Test func renewalUpdatesClientPlanType() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600)], in: context)
        let period = try PlanRenewalService(context: context, calendar: calendar)
            .renew(client: client, classCount: 4, planType: .shared, on: now)
        #expect(client.planType == .shared)
        #expect(period.sessions.allSatisfy { $0.planType == .shared })
    }

    // MARK: Sync

    @Test func syncTwiceDoesNotDuplicate() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600), (.thursday, 540)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        let period = try service.renew(client: client, classCount: 8, planType: .individual, on: now)
        try service.syncSessions(for: period, now: now)
        try service.syncSessions(for: period, now: now)
        #expect(period.sessions.count == 8)
    }

    @Test func syncDoesNotOverrideRescheduledClass() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.thursday, 540)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        let period = try service.renew(client: client, classCount: 4, planType: .individual, on: now)
        let session = try #require(period.sessions.first { $0.startsAt == TestSupport.date(2026, 9, 24, 9, 0) })
        let moved = TestSupport.date(2026, 9, 25, 7, 0)
        try RescheduleService(context: context, calendar: calendar).reschedule(session, to: moved, scope: .thisClassOnly)

        try service.syncSessions(for: period, now: now)

        #expect(session.startsAt == moved)
        #expect(period.sessions.count == 4)
    }

    @Test func slotChangeMovesOnlyFutureUnrescheduledClasses() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        let period = try service.renew(client: client, classCount: 4, planType: .individual, on: now)
        let slot = try #require(client.weeklySlots.first)
        slot.weekday = .wednesday
        slot.startMinuteOfDay = 720

        try service.syncSessions(for: period, now: now)

        let starts = period.sessions.map(\.startsAt).sorted()
        #expect(starts == [
            TestSupport.date(2026, 9, 14, 10, 0), // already happened, untouched
            TestSupport.date(2026, 9, 23, 12, 0),
            TestSupport.date(2026, 9, 30, 12, 0),
            TestSupport.date(2026, 10, 7, 12, 0),
        ])
    }

    @Test func slotChangeIntoATakenSlotChangesNothing() throws {
        let context = try TestSupport.makeContext()
        let blocker = TestSupport.makeClient("B", planType: .individual, slots: [(.wednesday, 720)], in: context)
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        try service.renew(client: blocker, classCount: 4, planType: .individual, on: now)
        let period = try service.renew(client: client, classCount: 4, planType: .individual, on: now)
        let slot = try #require(client.weeklySlots.first)
        slot.weekday = .wednesday
        slot.startMinuteOfDay = 720

        #expect(throws: SchedulingError.self) { try service.syncSessions(for: period, now: now) }
        #expect(period.sessions.allSatisfy { calendar.weekday(of: $0.startsAt) == .monday })
    }

    @Test func syncCreatesMissingFutureClassesForANewSlot() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("A", planType: .individual, slots: [(.monday, 600)], in: context)
        let service = PlanRenewalService(context: context, calendar: calendar)
        let period = try service.renew(client: client, classCount: 4, planType: .individual, on: now)
        let extra = WeeklySlot(weekday: .friday, startMinuteOfDay: 480, order: 2)
        context.insert(extra)
        extra.client = client

        try service.syncSessions(for: period, now: now)

        let fridays = period.sessions.filter { $0.sourceSlot?.id == extra.id }
        #expect(fridays.count == 4)
        #expect(fridays.allSatisfy { $0.startsAt >= now })
    }
}
