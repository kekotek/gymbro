import Foundation

/// Explicit status recorded by the trainer.
nonisolated enum SessionStatus: String, Codable {
    case scheduled
    /// Marked as done ("Marcar como realizada"). Assumption (open question 8): a class whose end
    /// time has passed also counts as completed even if it was never marked.
    case completed
    /// Cancelled ("Cancelar clase"). Assumption (open question 7): the class is lost, it is not
    /// recovered and the slot becomes free.
    case cancelled
}

/// Effective state of a class at a given instant, combining the stored status and the clock.
nonisolated enum SessionState: Equatable {
    case scheduled
    case completed
    case cancelled

    static func resolve(status: SessionStatus, endsAt: Date, now: Date) -> SessionState {
        switch status {
        case .cancelled: return .cancelled
        case .completed: return .completed
        case .scheduled: return endsAt <= now ? .completed : .scheduled
        }
    }
}
