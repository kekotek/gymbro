import Foundation

/// How many people can share a time slot with this client.
nonisolated enum PlanType: String, Codable, CaseIterable {
    /// The client trains alone; no other class may overlap.
    case individual
    /// Up to `GymSchedule.maxSharedClientsPerSlot` shared clients may train at the same time.
    case shared
}
