import Foundation
import SwiftData

@Model
final class Client {
    @Attribute(.unique) var id: UUID
    var fullName: String
    var birthDate: Date
    /// Current weight; updated by the latest InBody measurement.
    var weightKg: Double
    /// Plan type proposed for the next renewal and used when the client has no period yet.
    /// The type in force for a class comes from its `PlanPeriod`.
    var planType: PlanType
    /// Deactivate instead of deleting, to keep history.
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \PlanPeriod.client)
    var planPeriods: [PlanPeriod] = []
    @Relationship(deleteRule: .cascade, inverse: \WeeklySlot.client)
    var weeklySlots: [WeeklySlot] = []
    @Relationship(deleteRule: .cascade, inverse: \ClassSession.client)
    var sessions: [ClassSession] = []
    @Relationship(deleteRule: .cascade, inverse: \InBodyMeasurement.client)
    var inBodyMeasurements: [InBodyMeasurement] = []

    init(
        id: UUID = UUID(),
        fullName: String,
        birthDate: Date,
        weightKg: Double,
        planType: PlanType,
        isActive: Bool = true
    ) {
        self.id = id
        self.fullName = fullName
        self.birthDate = birthDate
        self.weightKg = weightKg
        self.planType = planType
        self.isActive = isActive
    }

    /// Age is derived from the birth date, never stored.
    func age(on date: Date = .now, calendar: Calendar = .gymbro()) -> Int {
        calendar.dateComponents([.year], from: birthDate, to: date).year ?? 0
    }

    func activePeriod(on date: Date) -> PlanPeriod? {
        planPeriods.first { $0.contains(date) }
    }

    var latestPeriod: PlanPeriod? {
        planPeriods.max { $0.startDate < $1.startDate }
    }

    var sortedWeeklySlots: [WeeklySlot] {
        weeklySlots.sorted { $0.order < $1.order }
    }

    var latestMeasurement: InBodyMeasurement? {
        inBodyMeasurements.max { $0.date < $1.date }
    }

    /// Adds a measurement and, if it is the most recent one, takes its weight as the current weight.
    func recordMeasurement(_ measurement: InBodyMeasurement) {
        let otherDates = inBodyMeasurements.map(\.date)
        inBodyMeasurements.append(measurement)
        if InBodyRules.isLatest(measurement.date, among: otherDates) {
            weightKg = measurement.weightKg
        }
    }
}
