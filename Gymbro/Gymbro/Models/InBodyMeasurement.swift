import Foundation
import SwiftData

@Model
final class InBodyMeasurement {
    @Attribute(.unique) var id: UUID
    var client: Client?
    var date: Date
    var weightKg: Double
    var bodyFatPercent: Double?
    /// Shown as "Músculo" in the reference profile screen.
    var muscleMassKg: Double?

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        date: Date,
        weightKg: Double,
        bodyFatPercent: Double? = nil,
        muscleMassKg: Double? = nil
    ) {
        self.id = id
        self.client = client
        self.date = date
        self.weightKg = weightKg
        self.bodyFatPercent = bodyFatPercent
        self.muscleMassKg = muscleMassKg
    }
}
