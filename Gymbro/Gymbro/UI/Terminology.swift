import Foundation

/// The word used for the people the trainer coaches. It is not final (open question 9), so every
/// view takes it from here.
enum Terminology {
    static var clientsTitle: String {
        String(localized: "Alumnos", comment: "Plural, used as tab and screen title")
    }

    static var clientSingular: String {
        String(localized: "alumno", comment: "Singular, lowercase, inside sentences")
    }
}
