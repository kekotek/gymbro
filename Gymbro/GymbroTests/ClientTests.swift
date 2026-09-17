import Foundation
import SwiftData
import Testing
@testable import Gymbro

@Suite struct ClientTests {
    let calendar = TestSupport.calendar

    @Test func ageIsDerivedFromBirthDate() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("Francisca", planType: .shared, in: context)
        #expect(client.age(on: TestSupport.now, calendar: calendar) == 32)
        #expect(client.age(on: TestSupport.date(2027, 3, 11), calendar: calendar) == 32)
        #expect(client.age(on: TestSupport.date(2027, 3, 12), calendar: calendar) == 33)
    }

    @Test func latestMeasurementUpdatesWeight() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("Francisca", planType: .shared, in: context)
        client.recordMeasurement(InBodyMeasurement(date: TestSupport.date(2026, 8, 10), weightKg: 63.9, bodyFatPercent: 25.0))
        #expect(client.weightKg == 63.9)

        client.recordMeasurement(InBodyMeasurement(date: TestSupport.date(2026, 9, 7), weightKg: 63.4, bodyFatPercent: 24.1, muscleMassKg: 26.8))
        #expect(client.weightKg == 63.4)
        #expect(client.latestMeasurement?.muscleMassKg == 26.8)
    }

    @Test func olderMeasurementDoesNotUpdateWeight() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("Francisca", planType: .shared, in: context)
        client.recordMeasurement(InBodyMeasurement(date: TestSupport.date(2026, 9, 7), weightKg: 63.4))
        client.recordMeasurement(InBodyMeasurement(date: TestSupport.date(2026, 6, 15), weightKg: 65.2))
        #expect(client.weightKg == 63.4)
        #expect(client.inBodyMeasurements.count == 2)
    }

    @Test func sessionStateFollowsStatusAndClock() {
        let start = TestSupport.date(2026, 9, 17, 7, 0)
        let end = calendar.sessionEnd(startingAt: start)
        #expect(SessionState.resolve(status: .scheduled, endsAt: end, now: TestSupport.date(2026, 9, 17, 7, 59)) == .scheduled)
        #expect(SessionState.resolve(status: .scheduled, endsAt: end, now: TestSupport.date(2026, 9, 17, 8, 0)) == .completed)
        #expect(SessionState.resolve(status: .completed, endsAt: end, now: TestSupport.date(2026, 9, 17, 6, 0)) == .completed)
        #expect(SessionState.resolve(status: .cancelled, endsAt: end, now: TestSupport.date(2026, 9, 17, 9, 0)) == .cancelled)
    }

    @Test func completedCountMatchesProfileScreen() throws {
        // "van 2 de 12" on Thursday 17 at 08:20 with classes Mon 10:00, Tue 09:00, Thu 09:00.
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("Francisca", planType: .shared, slots: [(.monday, 600), (.tuesday, 540), (.thursday, 540)], in: context)
        let period = try PlanRenewalService(context: context, calendar: calendar)
            .renew(client: client, classCount: 12, planType: .shared, on: TestSupport.now)
        #expect(period.completedCount(at: TestSupport.now, calendar: calendar) == 2)
    }
}
