#if DEBUG
import Foundation
import SwiftData

/// Debug-only data mirroring the reference screens, so the app has something to show before the
/// trainer enters real clients. Seeded once, when the store has no clients.
enum SampleData {
    static func seedIfNeeded(in context: ModelContext, now: Date = .now) {
        do {
            guard try context.fetchCount(FetchDescriptor<Client>()) == 0 else { return }
            try seed(in: context, now: now)
            try context.save()
        } catch {
            print("Sample data could not be seeded: \(error)")
        }
    }

    private struct ClientSeed {
        let name: String
        let birth: (Int, Int, Int)
        let weight: Double
        let planType: PlanType
        let classCount: Int
        /// 0 = renewed this week; 3 = renewed three weeks ago (plan ends this Sunday).
        let renewedWeeksAgo: Int
        let slots: [(Weekday, Int, String)]
    }

    private static let seeds: [ClientSeed] = [
        ClientSeed(name: "Benjamín Araya", birth: (1998, 5, 3), weight: 78.2, planType: .shared, classCount: 8, renewedWeeksAgo: 0,
                   slots: [(.monday, 19 * 60, "Pecho y tríceps"), (.thursday, 19 * 60, "Piernas")]),
        ClientSeed(name: "Camila Rojas", birth: (1991, 11, 22), weight: 58.7, planType: .shared, classCount: 12, renewedWeeksAgo: 0,
                   slots: [(.monday, 7 * 60, "Piernas"), (.thursday, 7 * 60, "Espalda y hombros"), (.saturday, 8 * 60, "Full body")]),
        ClientSeed(name: "Daniela Vera", birth: (1989, 2, 14), weight: 61.0, planType: .individual, classCount: 16, renewedWeeksAgo: 0,
                   slots: [(.tuesday, 7 * 60, "Piernas"), (.wednesday, 18 * 60, "Pecho y tríceps"), (.friday, 19 * 60, "Espalda y hombros"), (.saturday, 11 * 60, "Glúteos y core")]),
        ClientSeed(name: "Francisca Muñoz", birth: (1994, 3, 12), weight: 63.4, planType: .shared, classCount: 12, renewedWeeksAgo: 0,
                   slots: [(.monday, 10 * 60, "Pecho y tríceps"), (.tuesday, 9 * 60, "Piernas"), (.thursday, 9 * 60, "Espalda y hombros")]),
        ClientSeed(name: "Ignacio Paredes", birth: (1985, 7, 30), weight: 84.5, planType: .individual, classCount: 12, renewedWeeksAgo: 3,
                   slots: [(.monday, 6 * 60, "Pecho y tríceps"), (.wednesday, 6 * 60, "Espalda y hombros"), (.thursday, 6 * 60, "Piernas")]),
        ClientSeed(name: "Josefa Contreras", birth: (2000, 9, 9), weight: 55.3, planType: .shared, classCount: 8, renewedWeeksAgo: 0,
                   slots: [(.tuesday, 19 * 60, "Full body"), (.thursday, 19 * 60, "Piernas")]),
        ClientSeed(name: "Matías Fuentes", birth: (1993, 1, 17), weight: 80.1, planType: .individual, classCount: 16, renewedWeeksAgo: 0,
                   slots: [(.monday, 8 * 60, "Pecho y tríceps"), (.wednesday, 8 * 60, "Espalda y hombros"), (.thursday, 18 * 60, "Piernas"), (.saturday, 10 * 60, "Full body")]),
        ClientSeed(name: "Tomás Herrera", birth: (1996, 12, 1), weight: 74.8, planType: .individual, classCount: 16, renewedWeeksAgo: 0,
                   slots: [(.monday, 12 * 60, "Pecho y tríceps"), (.wednesday, 10 * 60 + 30, "Piernas"), (.friday, 11 * 60, "Espalda y hombros"), (.saturday, 9 * 60, "Full body")]),
        ClientSeed(name: "Valentina Soto", birth: (1997, 4, 25), weight: 59.9, planType: .shared, classCount: 12, renewedWeeksAgo: 0,
                   slots: [(.wednesday, 7 * 60, "Piernas"), (.thursday, 7 * 60, "Espalda y hombros"), (.friday, 7 * 60, "Glúteos y core")]),
    ]

    private static func seed(in context: ModelContext, now: Date) throws {
        let calendar = Calendar.gymbro()
        let weekStart = calendar.startOfWeek(containing: now)
        let renewal = PlanRenewalService(context: context, calendar: calendar)

        var routines: [String: Routine] = [:]
        func routine(_ name: String) -> Routine {
            if let existing = routines[name] { return existing }
            let created = Routine(name: name)
            context.insert(created)
            routines[name] = created
            return created
        }

        var clients: [String: Client] = [:]
        for seed in seeds {
            let birthDate = calendar.date(from: DateComponents(year: seed.birth.0, month: seed.birth.1, day: seed.birth.2))!
            let client = Client(fullName: seed.name, birthDate: birthDate, weightKg: seed.weight, planType: seed.planType)
            context.insert(client)
            for (index, slot) in seed.slots.enumerated() {
                let weeklySlot = WeeklySlot(weekday: slot.0, startMinuteOfDay: slot.1, order: index + 1, routine: routine(slot.2))
                context.insert(weeklySlot)
                weeklySlot.client = client
            }
            let renewalDate = calendar.date(byAdding: .weekOfYear, value: -seed.renewedWeeksAgo, to: weekStart)!
            try renewal.renew(client: client, classCount: seed.classCount, planType: seed.planType, on: renewalDate)
            clients[seed.name] = client
        }

        // Tomás moved this week's Wednesday class to Thursday 10:30 ("Movida desde mié").
        if let tomas = clients["Tomás Herrera"],
           let wednesday = tomas.sessions.first(where: {
               calendar.weekday(of: $0.startsAt) == .wednesday && $0.startsAt >= weekStart && $0.weekIndex == 0
           }),
           let target = calendar.date(weekStart: weekStart, weekday: .thursday, minuteOfDay: 10 * 60 + 30) {
            try RescheduleService(context: context, calendar: calendar).reschedule(wednesday, to: target, scope: .thisClassOnly)
        }

        // Francisca's InBody history, as in the profile screen.
        if let francisca = clients["Francisca Muñoz"] {
            let history: [(daysAgo: Int, weight: Double, fat: Double, muscle: Double)] = [
                (94, 65.2, 26.0, 25.9), (66, 64.6, 25.4, 26.1), (38, 63.9, 24.7, 26.5), (10, 63.4, 24.1, 26.8),
            ]
            for entry in history {
                let date = calendar.date(byAdding: .day, value: -entry.daysAgo, to: calendar.startOfDay(for: now))!
                let measurement = InBodyMeasurement(date: date, weightKg: entry.weight, bodyFatPercent: entry.fat, muscleMassKg: entry.muscle)
                context.insert(measurement)
                francisca.recordMeasurement(measurement)
            }
        }
    }
}
#endif
