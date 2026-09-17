import Foundation
import Testing
@testable import Gymbro

@Suite struct CalendarMathTests {
    let calendar = TestSupport.calendar

    @Test func weekStartsOnMonday() {
        let sunday = TestSupport.date(2026, 9, 20, 15, 0)
        #expect(calendar.startOfWeek(containing: sunday) == TestSupport.date(2026, 9, 14))
        #expect(calendar.startOfWeek(containing: TestSupport.date(2026, 9, 14, 0, 0)) == TestSupport.date(2026, 9, 14))
    }

    @Test func weekCrossingNewYearStartsInPreviousYear() {
        let newYear = TestSupport.date(2027, 1, 1, 10, 0)
        #expect(calendar.startOfWeek(containing: newYear) == TestSupport.date(2026, 12, 28))
    }

    @Test func visibleWeeksAreCurrentPlusFour() {
        let weeks = calendar.weeks(from: TestSupport.now, count: GymSchedule.visibleWeekCount)
        #expect(weeks.map(\.start) == [
            TestSupport.date(2026, 9, 14), TestSupport.date(2026, 9, 21), TestSupport.date(2026, 9, 28),
            TestSupport.date(2026, 10, 5), TestSupport.date(2026, 10, 12),
        ])
        #expect(weeks.last?.end == TestSupport.date(2026, 10, 19))
    }

    @Test func weekdayMapping() {
        #expect(calendar.weekday(of: TestSupport.date(2026, 9, 14)) == .monday)
        #expect(calendar.weekday(of: TestSupport.date(2026, 9, 17)) == .thursday)
        #expect(calendar.weekday(of: TestSupport.date(2026, 9, 20)) == .sunday)
        for weekday in Weekday.allCases {
            #expect(Weekday(calendarComponent: weekday.calendarComponent) == weekday)
        }
    }

    @Test func minuteOfDayAndSessionEnd() {
        let start = TestSupport.date(2026, 9, 17, 10, 30)
        #expect(calendar.minuteOfDay(of: start) == 630)
        #expect(calendar.sessionEnd(startingAt: start) == TestSupport.date(2026, 9, 17, 11, 30))
    }

    @Test func dateInWeekBuildsRequestedWeekdayAndTime() {
        let monday = TestSupport.date(2026, 9, 14)
        let saturday = calendar.date(weekStart: monday, weekday: .saturday, minuteOfDay: 9 * 60)
        #expect(saturday == TestSupport.date(2026, 9, 19, 9, 0))
    }
}
