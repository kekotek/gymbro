import Foundation

/// Classes that start at the same instant, drawn as one block in the calendar. A shared slot with
/// two clients is one group with two sessions.
struct SessionGroup: Identifiable {
    enum Kind {
        case individual
        /// Shared slot with room for another client.
        case sharedOpen
        case sharedFull
    }

    let startsAt: Date
    let sessions: [ClassSession]

    var id: UUID { sessions[0].id }

    var kind: Kind {
        if sessions.contains(where: { $0.planType == .individual }) { return .individual }
        return sessions.count >= GymSchedule.maxSharedClientsPerSlot ? .sharedFull : .sharedOpen
    }

    var clientNames: [String] { sessions.compactMap { $0.client?.fullName } }

    var initials: [String] { clientNames.map(Self.initials(of:)) }

    var routineNames: [String] {
        var names: [String] = []
        for name in sessions.compactMap({ $0.routine?.name }) where !names.contains(name) {
            names.append(name)
        }
        return names
    }

    var isRescheduled: Bool { sessions.contains(where: \.isRescheduled) }

    var originalStartsAt: Date? { sessions.compactMap(\.originalStartsAt).first }

    /// Completed once every class in the group is completed.
    func state(at now: Date, calendar: Calendar) -> SessionState {
        let states = sessions.map { $0.state(at: now, calendar: calendar) }
        return states.allSatisfy { $0 == .completed } ? .completed : .scheduled
    }

    /// Groups non-cancelled classes by start minute, sorted by start.
    static func groups(from sessions: [ClassSession], calendar: Calendar) -> [SessionGroup] {
        let active = sessions.filter { $0.status != .cancelled }
        var byStart: [Date: [ClassSession]] = [:]
        for session in active {
            let key = calendar.date(bySetting: .second, value: 0, of: session.startsAt) ?? session.startsAt
            byStart[key, default: []].append(session)
        }
        return byStart
            .map { SessionGroup(startsAt: $0.key, sessions: $0.value.sorted { ($0.client?.fullName ?? "") < ($1.client?.fullName ?? "") }) }
            .sorted { $0.startsAt < $1.startsAt }
    }

    /// "Francisca Muñoz" → "FM".
    nonisolated static func initials(of fullName: String) -> String {
        fullName.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0).uppercased() }.joined()
    }
}
