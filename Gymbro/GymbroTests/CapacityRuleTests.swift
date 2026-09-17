import Foundation
import Testing
@testable import Gymbro

@Suite struct CapacityRuleTests {
    let calendar = TestSupport.calendar
    let me = UUID()
    let other = UUID()
    let third = UUID()
    let eight = TestSupport.date(2026, 9, 14, 8, 0)
    let eightThirty = TestSupport.date(2026, 9, 14, 8, 30)
    let nine = TestSupport.date(2026, 9, 14, 9, 0)

    func evaluate(_ planType: PlanType, at start: Date, existing: [Booking], ignoring: UUID? = nil) -> PlacementResult {
        CapacityRule.evaluate(TestSupport.request(me, planType, at: start), existing: existing, ignoring: ignoring, calendar: calendar)
    }

    // MARK: Capacity table

    @Test func emptySlotAcceptsIndividualAndShared() {
        #expect(evaluate(.individual, at: eight, existing: []) == .allowed(sharingWith: []))
        #expect(evaluate(.shared, at: eight, existing: []) == .allowed(sharingWith: []))
    }

    @Test func slotWithIndividualRejectsEveryone() {
        let existing = [TestSupport.booking(other, .individual, at: eight)]
        #expect(evaluate(.individual, at: eight, existing: existing) == .rejected(.blockedByIndividual))
        #expect(evaluate(.shared, at: eight, existing: existing) == .rejected(.blockedByIndividual))
    }

    @Test func slotWithOneSharedAcceptsOnlyShared() {
        let existing = [TestSupport.booking(other, .shared, at: eight)]
        #expect(evaluate(.individual, at: eight, existing: existing) == .rejected(.individualCannotShare))
        #expect(evaluate(.shared, at: eight, existing: existing) == .allowed(sharingWith: [other]))
    }

    @Test func slotWithTwoSharedIsFull() {
        let existing = [TestSupport.booking(other, .shared, at: eight), TestSupport.booking(third, .shared, at: eight)]
        #expect(evaluate(.individual, at: eight, existing: existing) == .rejected(.individualCannotShare))
        #expect(evaluate(.shared, at: eight, existing: existing) == .rejected(.sharedFull))
    }

    // MARK: Time limits

    @Test func beforeOpeningIsRejected() {
        #expect(evaluate(.individual, at: TestSupport.date(2026, 9, 14, 5, 30), existing: []) == .rejected(.outsideGymHours))
    }

    @Test func openingTimeIsAccepted() {
        #expect(evaluate(.individual, at: TestSupport.date(2026, 9, 14, 6, 0), existing: []).isAllowed)
    }

    @Test func lastStartIsAccepted() {
        #expect(evaluate(.individual, at: TestSupport.date(2026, 9, 14, 21, 0), existing: []).isAllowed)
    }

    @Test func startAfterLastStartIsRejected() {
        #expect(evaluate(.individual, at: TestSupport.date(2026, 9, 14, 21, 30), existing: []) == .rejected(.outsideGymHours))
    }

    @Test func quarterPastIsRejected() {
        #expect(evaluate(.individual, at: TestSupport.date(2026, 9, 14, 8, 15), existing: []) == .rejected(.invalidStartMinute))
    }

    @Test func sundayIsNotAWorkingDay() {
        #expect(evaluate(.individual, at: TestSupport.date(2026, 9, 20, 9, 0), existing: []) == .rejected(.outsideWorkingDays))
        #expect(evaluate(.individual, at: TestSupport.date(2026, 9, 19, 9, 0), existing: []).isAllowed)
    }

    @Test func noActivePlanIsRejected() {
        let result = CapacityRule.evaluate(
            TestSupport.request(me, .shared, at: eight, hasActivePlan: false), existing: [], calendar: calendar
        )
        #expect(result == .rejected(.noActivePlan))
    }

    // MARK: Overlaps

    @Test func individualAtEightBlocksAnyoneAtEightThirty() {
        let existing = [TestSupport.booking(other, .individual, at: eight)]
        #expect(evaluate(.individual, at: eightThirty, existing: existing) == .rejected(.blockedByIndividual))
        #expect(evaluate(.shared, at: eightThirty, existing: existing) == .rejected(.blockedByIndividual))
    }

    @Test func individualCannotOverlapASharedClass() {
        let existing = [TestSupport.booking(other, .shared, at: eight)]
        #expect(evaluate(.individual, at: eightThirty, existing: existing) == .rejected(.individualCannotShare))
    }

    @Test func sharedClassesOnlyShareWhenTheyStartTogether() {
        let existing = [TestSupport.booking(other, .shared, at: eight)]
        #expect(evaluate(.shared, at: eightThirty, existing: existing) == .rejected(.sharedPartialOverlap))
    }

    @Test func contiguousClassesDoNotOverlap() {
        let existing = [TestSupport.booking(other, .individual, at: eight)]
        #expect(evaluate(.individual, at: nine, existing: existing).isAllowed)
        #expect(evaluate(.individual, at: TestSupport.date(2026, 9, 14, 7, 0), existing: existing).isAllowed)
    }

    @Test func sameClientCannotOverlapItself() {
        let existing = [TestSupport.booking(me, .shared, at: eight)]
        #expect(evaluate(.shared, at: eightThirty, existing: existing) == .rejected(.sameClientOverlap))
    }

    @Test func ignoredSessionDoesNotBlockItself() {
        let own = Booking(sessionID: UUID(), clientID: me, planType: .individual, startsAt: eight)
        #expect(evaluate(.individual, at: eightThirty, existing: [own], ignoring: own.sessionID).isAllowed)
        #expect(evaluate(.individual, at: eightThirty, existing: [own]) == .rejected(.sameClientOverlap))
    }

    @Test func classesOnDifferentDaysDoNotOverlap() {
        let existing = [TestSupport.booking(other, .individual, at: TestSupport.date(2026, 9, 15, 8, 0))]
        #expect(evaluate(.individual, at: eight, existing: existing).isAllowed)
    }

    // MARK: Schedule constants

    @Test func startMinutesCoverOpeningHours() {
        let minutes = GymSchedule.allStartMinutes
        #expect(minutes.first == 6 * 60)
        #expect(minutes.last == 21 * 60)
        #expect(minutes.count == 31)
    }
}
