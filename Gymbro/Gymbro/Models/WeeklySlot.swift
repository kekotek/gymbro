import Foundation
import SwiftData

/// The fixed weekly time of one of the client's classes.
@Model
final class WeeklySlot {
    @Attribute(.unique) var id: UUID
    var client: Client?
    var weekday: Weekday
    /// Minutes since midnight: 360 (06:00) to 1260 (21:00), multiple of 30.
    var startMinuteOfDay: Int
    /// Class 1, 2, 3… within the client's week.
    var order: Int
    var routine: Routine?

    @Relationship(deleteRule: .nullify, inverse: \ClassSession.sourceSlot)
    var sessions: [ClassSession] = []

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        weekday: Weekday,
        startMinuteOfDay: Int,
        order: Int,
        routine: Routine? = nil
    ) {
        self.id = id
        self.client = client
        self.weekday = weekday
        self.startMinuteOfDay = startMinuteOfDay
        self.order = order
        self.routine = routine
    }

    var spec: SlotSpec {
        SlotSpec(slotID: id, weekday: weekday, startMinuteOfDay: startMinuteOfDay)
    }

    var hasValidTime: Bool {
        GymSchedule.isValidStartMinute(startMinuteOfDay) && GymSchedule.workingWeekdays.contains(weekday)
    }
}
