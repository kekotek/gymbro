import Foundation
import SwiftData

enum GymbroSchema {
    static let models: [any PersistentModel.Type] = [
        Client.self,
        PlanPeriod.self,
        WeeklySlot.self,
        ClassSession.self,
        Routine.self,
        InBodyMeasurement.self,
    ]

    static var schema: Schema { Schema(models) }
}
