import Foundation

/// Spanish (Chile) date and time strings shaped like the reference screens.
enum DateText {
    static let shortMonths: [String] = [
        String(localized: "ene"), String(localized: "feb"), String(localized: "mar"), String(localized: "abr"),
        String(localized: "may"), String(localized: "jun"), String(localized: "jul"), String(localized: "ago"),
        String(localized: "sep"), String(localized: "oct"), String(localized: "nov"), String(localized: "dic"),
    ]

    static let longMonths: [String] = [
        String(localized: "enero"), String(localized: "febrero"), String(localized: "marzo"), String(localized: "abril"),
        String(localized: "mayo"), String(localized: "junio"), String(localized: "julio"), String(localized: "agosto"),
        String(localized: "septiembre"), String(localized: "octubre"), String(localized: "noviembre"), String(localized: "diciembre"),
    ]

    static let weekdayLetters: [Weekday: String] = [
        .monday: String(localized: "L", comment: "Weekday letter for lunes"),
        .tuesday: String(localized: "M", comment: "Weekday letter for martes"),
        .wednesday: String(localized: "X", comment: "Weekday letter for miércoles"),
        .thursday: String(localized: "J", comment: "Weekday letter for jueves"),
        .friday: String(localized: "V", comment: "Weekday letter for viernes"),
        .saturday: String(localized: "S", comment: "Weekday letter for sábado"),
        .sunday: String(localized: "D", comment: "Weekday letter for domingo"),
    ]

    static let shortWeekdays: [Weekday: String] = [
        .monday: String(localized: "lun"), .tuesday: String(localized: "mar"), .wednesday: String(localized: "mié"),
        .thursday: String(localized: "jue"), .friday: String(localized: "vie"), .saturday: String(localized: "sáb"),
        .sunday: String(localized: "dom"),
    ]

    static let longWeekdays: [Weekday: String] = [
        .monday: String(localized: "lunes"), .tuesday: String(localized: "martes"), .wednesday: String(localized: "miércoles"),
        .thursday: String(localized: "jueves"), .friday: String(localized: "viernes"), .saturday: String(localized: "sábado"),
        .sunday: String(localized: "domingo"),
    ]

    /// "los jueves", "los sábados"
    static func weekdayPlural(_ weekday: Weekday) -> String {
        switch weekday {
        case .saturday: return String(localized: "sábados")
        case .sunday: return String(localized: "domingos")
        default: return longWeekdays[weekday] ?? ""
        }
    }

    /// "12 mar 1994"
    static func fullDate(_ date: Date, calendar: Calendar) -> String {
        "\(dayAndMonth(date, calendar: calendar)) \(calendar.component(.year, from: date))"
    }

    static func decimal(_ value: Double, fractionDigits: Int = 1) -> String {
        value.formatted(.number.precision(.fractionLength(fractionDigits)).locale(Locale(identifier: "es_CL")))
    }

    static func day(_ date: Date, calendar: Calendar) -> Int {
        calendar.component(.day, from: date)
    }

    static func shortMonth(_ date: Date, calendar: Calendar) -> String {
        shortMonths[calendar.component(.month, from: date) - 1]
    }

    /// "14 sep"
    static func dayAndMonth(_ date: Date, calendar: Calendar) -> String {
        "\(day(date, calendar: calendar)) \(shortMonth(date, calendar: calendar))"
    }

    /// "14–20 sep" or "28 sep – 4 oct"
    static func weekRange(_ week: DateInterval, calendar: Calendar) -> String {
        let last = calendar.date(byAdding: .day, value: -1, to: week.end)!
        if calendar.isDate(week.start, equalTo: last, toGranularity: .month) {
            return "\(day(week.start, calendar: calendar))–\(day(last, calendar: calendar)) \(shortMonth(last, calendar: calendar))"
        }
        return "\(dayAndMonth(week.start, calendar: calendar)) – \(dayAndMonth(last, calendar: calendar))"
    }

    /// "Jueves 17"
    static func dayTitle(_ date: Date, calendar: Calendar) -> String {
        let weekday = longWeekdays[calendar.weekday(of: date)] ?? ""
        return "\(weekday.capitalized) \(day(date, calendar: calendar))"
    }

    /// "jueves 17 de septiembre"
    static func longDate(_ date: Date, calendar: Calendar) -> String {
        let weekday = longWeekdays[calendar.weekday(of: date)] ?? ""
        let month = longMonths[calendar.component(.month, from: date) - 1]
        return String(localized: "\(weekday) \(day(date, calendar: calendar)) de \(month)", comment: "Long date, e.g. jueves 17 de septiembre")
    }

    /// "mié 16"
    static func shortDay(_ date: Date, calendar: Calendar) -> String {
        "\(shortWeekdays[calendar.weekday(of: date)] ?? "") \(day(date, calendar: calendar))"
    }

    /// "dom 11 oct"
    static func shortDayMonth(_ date: Date, calendar: Calendar) -> String {
        "\(shortDay(date, calendar: calendar)) \(shortMonth(date, calendar: calendar))"
    }

    /// "09:00"
    static func time(_ date: Date, calendar: Calendar) -> String {
        timeOfDay(calendar.minuteOfDay(of: date))
    }

    /// "09:00" from minutes since midnight.
    static func timeOfDay(_ minuteOfDay: Int) -> String {
        String(format: "%02d:%02d", minuteOfDay / 60, minuteOfDay % 60)
    }

    /// "09:00 – 10:00"
    static func sessionRange(startingAt start: Date, calendar: Calendar) -> String {
        "\(time(start, calendar: calendar)) – \(time(calendar.sessionEnd(startingAt: start), calendar: calendar))"
    }
}
