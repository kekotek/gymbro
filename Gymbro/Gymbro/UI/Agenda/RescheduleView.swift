import SwiftUI
import SwiftData

/// Screen 04: move a class to another day and time.
struct RescheduleView: View {
    let session: ClassSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.fullName) private var clients: [Client]
    @State private var selectedDay: Date
    @State private var selectedStart: Date?
    @State private var scope: RescheduleScope = .thisClassOnly
    @State private var availability: [SlotAvailability] = []
    @State private var errorMessage: String?
    private let calendar = Calendar.gymbro()
    private let now = Date.now

    init(session: ClassSession) {
        self.session = session
        let calendar = Calendar.gymbro()
        let today = calendar.startOfDay(for: .now)
        let sessionDay = calendar.startOfDay(for: session.startsAt)
        _selectedDay = State(initialValue: max(today, sessionDay))
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: String(localized: "Reagendar clase")) { dismiss() }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCard
                    dayChips
                    timeGrid
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            bottomPanel
        }
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task(id: selectedDay) { loadAvailability() }
        .alert(String(localized: "No se pudo mover"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.client?.fullName ?? "")
                    .font(Theme.body(22, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(String(localized: "Plan \(UserFacingText.planType(session.planType))").uppercased())
                    .font(Theme.heading(15))
                    .tracking(1.5)
                    .foregroundStyle(session.planType == .shared ? Theme.cyan : Theme.lime)
            }
            HStack(spacing: 12) {
                Text("\(DateText.shortDay(session.startsAt, calendar: calendar)) · \(DateText.time(session.startsAt, calendar: calendar))")
                    .strikethrough(selectedStart != nil)
                    .foregroundStyle(Theme.textSecondary)
                Image(systemName: "arrow.right").foregroundStyle(Theme.textSecondary)
                if let target = selectedStart {
                    Text("\(DateText.shortDay(target, calendar: calendar)) · \(DateText.time(target, calendar: calendar))")
                        .foregroundStyle(Theme.lime)
                } else {
                    Text(String(localized: "elige una hora")).foregroundStyle(Theme.textSecondary)
                }
            }
            .font(Theme.heading(24))
            if let routine = session.routine?.name {
                Text(String(localized: "\(routine) · la rutina se mueve con la clase"))
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.textSecondary)
            }
            if let partner = sharingPartnerName {
                Label(String(localized: "Compartirá la hora con \(partner)"), systemImage: "person.2")
                    .font(Theme.body(18))
                    .foregroundStyle(Theme.cyan)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var sharingPartnerName: String? {
        guard let target = selectedStart,
              let slot = availability.first(where: { $0.startsAt == target }),
              case .allowed(let sharing) = slot.result, let partnerID = sharing.first else { return nil }
        return clients.first { $0.id == partnerID }?.fullName
    }

    // MARK: Days

    private var candidateDays: [Date] {
        guard let period = session.planPeriod else { return [] }
        let today = calendar.startOfDay(for: now)
        var days: [Date] = []
        var day = max(today, period.startDate)
        while day < period.endDate {
            if GymSchedule.workingWeekdays.contains(calendar.weekday(of: day)) { days.append(day) }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    private var dayChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(candidateDays, id: \.self) { day in
                    let selected = calendar.isDate(day, inSameDayAs: selectedDay)
                    Button {
                        selectedDay = day
                        selectedStart = nil
                    } label: {
                        VStack(spacing: 4) {
                            Text(calendar.isDateInToday(day) ? String(localized: "Hoy") : (DateText.shortWeekdays[calendar.weekday(of: day)] ?? "").capitalized)
                                .font(Theme.body(15, weight: .medium))
                            Text("\(DateText.day(day, calendar: calendar))")
                                .font(Theme.heading(26))
                        }
                        .foregroundStyle(selected ? Theme.onLime : Theme.textPrimary)
                        .frame(width: 64, height: 68)
                        .background(RoundedRectangle(cornerRadius: 14).fill(selected ? Theme.textPrimary : Theme.surface))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Times

    private var timeGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(availability) { slot in
                timeCell(slot)
            }
        }
    }

    private func timeCell(_ slot: SlotAvailability) -> some View {
        let isPast = slot.startsAt < now
        let selected = selectedStart == slot.startsAt
        let (caption, enabled): (String, Bool) = {
            if isPast { return (String(localized: "Pasada"), false) }
            switch slot.result {
            case .allowed(let sharing):
                if let partnerID = sharing.first, let partner = clients.first(where: { $0.id == partnerID }) {
                    return (String(localized: "c/ \(partner.fullName.split(separator: " ").first.map(String.init) ?? "")"), true)
                }
                return (String(localized: "Libre"), true)
            case .rejected:
                return (String(localized: "Ocupada"), false)
            }
        }()
        return Button {
            selectedStart = slot.startsAt
        } label: {
            VStack(spacing: 2) {
                Text(DateText.time(slot.startsAt, calendar: calendar)).font(Theme.heading(22))
                Text(caption).font(Theme.body(14)).lineLimit(1)
            }
            .foregroundStyle(selected ? Theme.onLime : (enabled ? Theme.textPrimary : Theme.textSecondary.opacity(0.7)))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Theme.lime : (enabled ? Theme.surface : Theme.surface.opacity(0.5))))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: Bottom

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SegmentedChoice(selection: $scope, options: [
                (.thisClassOnly, String(localized: "Solo esta clase")),
                (.fromNowOn, String(localized: "De aquí en adelante")),
            ])
            Text(scopeExplanation)
                .font(Theme.body(16))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(confirmTitle) { confirm() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedStart == nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.background.shadow(color: .black.opacity(0.4), radius: 12, y: -4))
    }

    private var scopeExplanation: String {
        let slotText: String = {
            guard let slot = session.sourceSlot else { return "" }
            return String(localized: "Su horario fijo de los \(DateText.weekdayPlural(slot.weekday)) a las \(DateText.timeOfDay(slot.startMinuteOfDay))")
        }()
        switch scope {
        case .thisClassOnly:
            return String(localized: "Se mueve solo la clase de \(DateText.shortDay(session.startsAt, calendar: calendar)). \(slotText) no cambia.")
        case .fromNowOn:
            guard let target = selectedStart else {
                return String(localized: "Cambia su horario fijo y se mueven las clases siguientes de este período.")
            }
            return String(localized: "\(slotText) pasa a los \(DateText.weekdayPlural(calendar.weekday(of: target))) a las \(DateText.time(target, calendar: calendar)), y se mueven las clases siguientes de este período.")
        }
    }

    private var confirmTitle: String {
        guard let target = selectedStart else { return String(localized: "Elige día y hora") }
        return String(localized: "Mover a \(DateText.shortDay(target, calendar: calendar)) · \(DateText.sessionRange(startingAt: target, calendar: calendar))")
    }

    private func loadAvailability() {
        do {
            availability = try RescheduleService(context: modelContext, calendar: calendar).availability(for: session, on: selectedDay)
        } catch {
            availability = []
            errorMessage = UserFacingText.text(for: error)
        }
    }

    private func confirm() {
        guard let target = selectedStart else { return }
        do {
            try RescheduleService(context: modelContext, calendar: calendar).reschedule(session, to: target, scope: scope)
            dismiss()
        } catch {
            errorMessage = UserFacingText.text(for: error)
        }
    }
}
