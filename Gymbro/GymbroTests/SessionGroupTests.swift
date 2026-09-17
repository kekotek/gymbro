import Foundation
import SwiftData
import Testing
@testable import Gymbro

@Suite struct SessionGroupTests {
    let calendar = TestSupport.calendar

    @Test func groupsSharedClientsStartingTogether() throws {
        let context = try TestSupport.makeContext()
        let camila = TestSupport.makeClient("Camila Rojas", planType: .shared, slots: [(.thursday, 420)], in: context)
        let valentina = TestSupport.makeClient("Valentina Soto", planType: .shared, slots: [(.thursday, 420)], in: context)
        let francisca = TestSupport.makeClient("Francisca Muñoz", planType: .shared, slots: [(.thursday, 540)], in: context)
        let tomas = TestSupport.makeClient("Tomás Herrera", planType: .individual, slots: [(.thursday, 630)], in: context)
        let renewal = PlanRenewalService(context: context, calendar: calendar)
        for client in [camila, valentina, francisca, tomas] {
            try renewal.renew(client: client, classCount: 4, planType: client.planType, on: TestSupport.now)
        }
        let thursday = TestSupport.date(2026, 9, 17)
        let sessions = try context.fetch(FetchDescriptor<ClassSession>()).filter { calendar.isDate($0.startsAt, inSameDayAs: thursday) }

        let groups = SessionGroup.groups(from: sessions, calendar: calendar)

        #expect(groups.map(\.kind) == [.sharedFull, .sharedOpen, .individual])
        #expect(groups[0].initials == ["CR", "VS"])
        #expect(groups[0].clientNames == ["Camila Rojas", "Valentina Soto"])
        #expect(groups[1].initials == ["FM"])
        #expect(groups[0].state(at: TestSupport.now, calendar: calendar) == .completed)
        #expect(groups[1].state(at: TestSupport.now, calendar: calendar) == .scheduled)
    }

    @Test func cancelledClassesAreNotGrouped() throws {
        let context = try TestSupport.makeContext()
        let client = TestSupport.makeClient("Tomás Herrera", planType: .individual, slots: [(.thursday, 630)], in: context)
        let period = try PlanRenewalService(context: context, calendar: calendar)
            .renew(client: client, classCount: 4, planType: .individual, on: TestSupport.now)
        period.sessions[0].cancel()
        #expect(SessionGroup.groups(from: period.sessions, calendar: calendar).count == 3)
    }

    @Test func initialsUseFirstTwoWords() {
        #expect(SessionGroup.initials(of: "Francisca Muñoz") == "FM")
        #expect(SessionGroup.initials(of: "ana maría pérez") == "AM")
        #expect(SessionGroup.initials(of: "Tomás") == "T")
    }
}
