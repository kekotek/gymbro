import Foundation
import SwiftData

/// Reads the classes that the capacity rule must consider for a date range.
struct BookingRepository {
    let context: ModelContext
    let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .gymbro()) {
        self.context = context
        self.calendar = calendar
    }

    /// Bookings that could overlap any class starting inside `interval`.
    func bookings(overlapping interval: DateInterval) throws -> [Booking] {
        let margin = GymSchedule.sessionDurationMinutes
        let from = calendar.date(byAdding: .minute, value: -margin, to: interval.start)!
        let to = calendar.date(byAdding: .minute, value: margin, to: interval.end)!
        let predicate = #Predicate<ClassSession> { $0.startsAt >= from && $0.startsAt < to }
        let sessions = try context.fetch(FetchDescriptor(predicate: predicate))
        return sessions.compactMap(\.booking)
    }

    /// Bookings that could overlap a class starting at `startsAt`.
    func bookings(around startsAt: Date) throws -> [Booking] {
        try bookings(overlapping: DateInterval(start: startsAt, end: startsAt))
    }
}
