import Foundation
import SwiftData

/// Training plan for a class (e.g. "Espalda y hombros"). Catalog shared between clients.
@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
