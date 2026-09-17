import Foundation

/// Launch arguments used to open the app on a given screen (screenshots, manual testing).
/// Example: `-agendaMode day -tab clients`.
enum LaunchOptions {
    static var initialAgendaMode: AgendaMode {
        value(after: "-agendaMode") == "day" ? .day : .week
    }

    static var initialTab: MainTab {
        value(after: "-tab") == "clients" ? .clients : .agenda
    }

    private static func value(after flag: String) -> String? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }
}
