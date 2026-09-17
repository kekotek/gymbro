import Foundation

nonisolated enum InBodyRules {
    /// True when `date` is the most recent among `otherDates` (ties count as latest).
    static func isLatest(_ date: Date, among otherDates: [Date]) -> Bool {
        otherDates.allSatisfy { $0 <= date }
    }
}
