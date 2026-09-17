import Foundation
import Testing
@testable import Gymbro

@Suite struct SessionGeneratorTests {
    let calendar = TestSupport.calendar

    func slot(_ weekday: Weekday, _ minute: Int) -> SlotSpec {
        SlotSpec(slotID: UUID(), weekday: weekday, startMinuteOfDay: minute)
    }

    @Test func threeSlotsProduceTwelveClassesInOrder() {
        let slots = [slot(.monday, 600), slot(.tuesday, 540), slot(.thursday, 540)]
        let planned = SessionGenerator.plan(slots: slots, periodStart: TestSupport.date(2026, 9, 14), calendar: calendar)
        #expect(planned.count == 12)
        #expect(planned.first?.startsAt == TestSupport.date(2026, 9, 14, 10, 0))
        #expect(planned.last?.startsAt == TestSupport.date(2026, 10, 8, 9, 0))
        #expect(planned.map(\.weekIndex) == [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3])
        #expect(planned == planned.sorted { $0.startsAt < $1.startsAt })
    }

    @Test func classesKeepLocalTimeAcrossDaylightSavingChangeInSeptember() {
        // Chile moves clocks forward on the first Sunday of September.
        let planned = SessionGenerator.plan(slots: [slot(.wednesday, 540)], periodStart: TestSupport.date(2026, 8, 31), calendar: calendar)
        #expect(planned.map(\.startsAt) == [
            TestSupport.date(2026, 9, 2, 9, 0), TestSupport.date(2026, 9, 9, 9, 0),
            TestSupport.date(2026, 9, 16, 9, 0), TestSupport.date(2026, 9, 23, 9, 0),
        ])
        for session in planned { #expect(calendar.minuteOfDay(of: session.startsAt) == 540) }
    }

    @Test func classesKeepLocalTimeAcrossDaylightSavingChangeInApril() {
        // Chile moves clocks back on the first Sunday of April.
        let planned = SessionGenerator.plan(slots: [slot(.saturday, 360)], periodStart: TestSupport.date(2026, 3, 30), calendar: calendar)
        #expect(planned.map(\.startsAt) == [
            TestSupport.date(2026, 4, 4, 6, 0), TestSupport.date(2026, 4, 11, 6, 0),
            TestSupport.date(2026, 4, 18, 6, 0), TestSupport.date(2026, 4, 25, 6, 0),
        ])
        for session in planned { #expect(calendar.minuteOfDay(of: session.startsAt) == 360) }
    }

    @Test func periodCrossingNewYear() {
        let planned = SessionGenerator.plan(slots: [slot(.friday, 1080)], periodStart: TestSupport.date(2026, 12, 21), calendar: calendar)
        #expect(planned.map(\.startsAt) == [
            TestSupport.date(2026, 12, 25, 18, 0), TestSupport.date(2027, 1, 1, 18, 0),
            TestSupport.date(2027, 1, 8, 18, 0), TestSupport.date(2027, 1, 15, 18, 0),
        ])
    }

    @Test func noSlotsProduceNoClasses() {
        #expect(SessionGenerator.plan(slots: [], periodStart: TestSupport.date(2026, 9, 14), calendar: calendar).isEmpty)
    }
}
