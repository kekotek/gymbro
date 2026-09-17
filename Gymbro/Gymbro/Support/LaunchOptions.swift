import Foundation

/// Launch arguments used to open the app on a given screen (screenshots, manual testing).
/// Example: `-tab clients -openClient Francisca -sheet renewal` or `-openClass 18:00 -sheet reschedule`.
/// Only honored in Debug builds.
enum LaunchOptions {
    static var initialAgendaMode: AgendaMode {
        value(after: "-agendaMode") == "day" ? .day : .week
    }

    static var initialTab: MainTab {
        value(after: "-tab") == "clients" ? .clients : .agenda
    }

    /// Part of a client name whose profile opens at launch.
    static var openClientName: String? { value(after: "-openClient") }

    /// "HH:mm" of a class today whose detail opens at launch.
    static var openClassTime: String? { value(after: "-openClass") }

    /// "reschedule" or "renewal": sheet presented on top of the opened screen.
    static var sheet: String? { value(after: "-sheet") }

    private static func value(after flag: String) -> String? {
        #if DEBUG
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
        #else
        return nil
        #endif
    }
}
