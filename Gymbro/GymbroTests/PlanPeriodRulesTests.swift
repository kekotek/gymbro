import Foundation
import Testing
@testable import Gymbro

@Suite struct PlanPeriodRulesTests {
    let calendar = TestSupport.calendar

    @Test func onlyFourEightTwelveSixteenAreValid() {
        for count in [4, 8, 12, 16] { #expect(PlanPeriodRules.isValidClassCount(count)) }
        for count in [0, 1, 3, 5, 10, 20, -4] { #expect(!PlanPeriodRules.isValidClassCount(count)) }
    }

    @Test func classesPerWeek() {
        #expect(PlanPeriodRules.classesPerWeek(for: 4) == 1)
        #expect(PlanPeriodRules.classesPerWeek(for: 16) == 4)
    }

    @Test func firstPeriodStartsOnMondayOfRenewalWeek() {
        let start = PlanPeriodRules.startDate(forRenewalOn: TestSupport.now, existingPeriods: [], calendar: calendar)
        #expect(start == TestSupport.date(2026, 9, 14))
    }

    @Test func earlyRenewalStartsAfterCurrentPeriod() {
        let current = DateInterval(start: TestSupport.date(2026, 9, 14), end: TestSupport.date(2026, 10, 12))
        let start = PlanPeriodRules.startDate(forRenewalOn: TestSupport.now, existingPeriods: [current], calendar: calendar)
        #expect(start == TestSupport.date(2026, 10, 12))
    }

    @Test func renewalAfterALapseStartsOnMondayOfRenewalWeek() {
        let old = DateInterval(start: TestSupport.date(2026, 6, 1), end: TestSupport.date(2026, 6, 29))
        let start = PlanPeriodRules.startDate(forRenewalOn: TestSupport.now, existingPeriods: [old], calendar: calendar)
        #expect(start == TestSupport.date(2026, 9, 14))
    }

    @Test func renewalOnTheWeekThePreviousPeriodEndsIsContiguous() {
        let current = DateInterval(start: TestSupport.date(2026, 9, 14), end: TestSupport.date(2026, 10, 12))
        let start = PlanPeriodRules.startDate(
            forRenewalOn: TestSupport.date(2026, 10, 15, 9, 0), existingPeriods: [current], calendar: calendar
        )
        #expect(start == TestSupport.date(2026, 10, 12))
    }

    @Test func periodLastsFourWeeks() {
        let end = PlanPeriodRules.endDate(for: TestSupport.date(2026, 9, 14), calendar: calendar)
        #expect(end == TestSupport.date(2026, 10, 12))
    }
}
