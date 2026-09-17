import Foundation
import SwiftData

/// One monthly renewal: four weeks with a fixed number of classes.
@Model
final class PlanPeriod {
    @Attribute(.unique) var id: UUID
    var client: Client?
    /// Monday 00:00.
    var startDate: Date
    /// Exclusive: the Monday four weeks after `startDate`.
    var endDate: Date
    /// 4, 8, 12 or 16.
    var classCount: Int
    /// Plan type chosen at renewal time (the reference renewal screen lets the trainer pick it).
    var planType: PlanType

    @Relationship(deleteRule: .cascade, inverse: \ClassSession.planPeriod)
    var sessions: [ClassSession] = []

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        startDate: Date,
        endDate: Date,
        classCount: Int,
        planType: PlanType
    ) {
        self.id = id
        self.client = client
        self.startDate = startDate
        self.endDate = endDate
        self.classCount = classCount
        self.planType = planType
    }

    var interval: DateInterval { DateInterval(start: startDate, end: endDate) }

    func contains(_ date: Date) -> Bool {
        startDate <= date && date < endDate
    }

    var classesPerWeek: Int { PlanPeriodRules.classesPerWeek(for: classCount) }

    /// Classes done so far ("van 2 de 12").
    func completedCount(at now: Date, calendar: Calendar = .gymbro()) -> Int {
        sessions.filter { $0.state(at: now, calendar: calendar) == .completed }.count
    }
}
