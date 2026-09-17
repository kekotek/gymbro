import Foundation
import SwiftData
import Testing
@testable import Gymbro

enum TestSupport {
    /// Chilean calendar so week, year and daylight-saving boundaries match production.
    static let calendar = Calendar.gymbro(timeZone: TimeZone(identifier: "America/Santiago")!)

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Thursday 17 September 2026 at 08:20, the instant shown in the reference screens.
    static let now = date(2026, 9, 17, 8, 20)

    static func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: GymbroSchema.schema, configurations: configuration)
        return ModelContext(container)
    }

    @discardableResult
    static func makeClient(
        _ name: String,
        planType: PlanType,
        slots: [(Weekday, Int)] = [],
        in context: ModelContext
    ) -> Client {
        let client = Client(fullName: name, birthDate: date(1994, 3, 12), weightKg: 60, planType: planType)
        context.insert(client)
        for (index, slot) in slots.enumerated() {
            let weeklySlot = WeeklySlot(weekday: slot.0, startMinuteOfDay: slot.1, order: index + 1)
            context.insert(weeklySlot)
            weeklySlot.client = client
        }
        return client
    }

    static func booking(_ clientID: UUID, _ planType: PlanType, at startsAt: Date) -> Booking {
        Booking(sessionID: UUID(), clientID: clientID, planType: planType, startsAt: startsAt)
    }

    static func request(_ clientID: UUID, _ planType: PlanType, at startsAt: Date, hasActivePlan: Bool = true) -> PlacementRequest {
        PlacementRequest(clientID: clientID, planType: planType, startsAt: startsAt, hasActivePlan: hasActivePlan)
    }

    static func minutes(_ hour: Int, _ minute: Int = 0) -> Int { hour * 60 + minute }
}
