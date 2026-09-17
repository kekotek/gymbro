import SwiftUI
import SwiftData

/// Screen 03: one class, with reschedule, cancel and mark-as-done actions.
struct ClassDetailView: View {
    let session: ClassSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showReschedule = LaunchOptions.sheet == "reschedule"
    @State private var showRoutinePicker = false
    @State private var showAddClient = false
    @State private var confirmCancel = false
    @State private var errorMessage: String?
    private let calendar = Calendar.gymbro()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            content(now: timeline.date)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showReschedule) { RescheduleView(session: session) }
        .sheet(isPresented: $showRoutinePicker) {
            RoutinePickerSheet(selected: session.routine) { session.routine = $0 }
        }
        .sheet(isPresented: $showAddClient) { AddSharedClientSheet(session: session) }
        .confirmationDialog(String(localized: "¿Cancelar esta clase?"), isPresented: $confirmCancel, titleVisibility: .visible) {
            Button(String(localized: "Cancelar clase"), role: .destructive) { session.cancel() }
            Button(String(localized: "Volver"), role: .cancel) {}
        } message: {
            Text(String(localized: "La clase se pierde y la hora queda libre."))
        }
        .alert(String(localized: "No se pudo guardar"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func content(now: Date) -> some View {
        let state = session.state(at: now, calendar: calendar)
        let partners = sharingPartners()
        return VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold))
                            Text(String(localized: "Agenda"))
                        }
                        .font(Theme.body(20, weight: .semibold))
                        .foregroundStyle(Theme.lime)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)

                    Text(DateText.sessionRange(startingAt: session.startsAt, calendar: calendar))
                        .font(Theme.display(52))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(dateLine)
                        .font(Theme.body(20))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 4)

                    stateBanner(state)
                        .padding(.top, 16)

                    VStack(spacing: 0) {
                        if let client = session.client {
                            NavigationLink(value: client) {
                                infoRow(title: client.fullName, subtitle: planLabel) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        CardDivider()
                        infoRow(title: session.routine?.name ?? String(localized: "Sin rutina"), subtitle: orderLabel) {
                            if state == .scheduled {
                                actionLabel(String(localized: "Cambiar")) { showRoutinePicker = true }
                            }
                        }
                        if session.planType == .shared {
                            CardDivider()
                            if partners.isEmpty {
                                infoRow(
                                    title: String(localized: "1 cupo libre"),
                                    subtitle: String(localized: "Para otro \(Terminology.clientSingular) con plan compartido"),
                                    titleColor: Theme.cyan
                                ) {
                                    if state == .scheduled {
                                        actionLabel(String(localized: "Agregar")) { showAddClient = true }
                                    }
                                }
                            } else {
                                infoRow(
                                    title: String(localized: "Comparte con \(partners.joined(separator: ", "))"),
                                    subtitle: String(localized: "Hora compartida completa")
                                ) { EmptyView() }
                            }
                        }
                    }
                    .cardBackground()
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        if let slot = session.sourceSlot {
                            Text(String(localized: "Horario fijo: todos los \(DateText.weekdayPlural(slot.weekday)) a las \(DateText.timeOfDay(slot.startMinuteOfDay))"))
                        }
                        if let original = session.originalStartsAt {
                            Text(String(localized: "Movida desde \(DateText.shortDay(original, calendar: calendar)) · \(DateText.time(original, calendar: calendar))"))
                        }
                    }
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 20)
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            if state == .scheduled {
                actions
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(String(localized: "Reagendar")) { showReschedule = true }
                    .buttonStyle(OutlineButtonStyle())
                Button(String(localized: "Cancelar clase")) { confirmCancel = true }
                    .buttonStyle(OutlineButtonStyle(color: Theme.coral, borderColor: Theme.line))
            }
            Button(String(localized: "Marcar como realizada")) { session.markCompleted() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func stateBanner(_ state: SessionState) -> some View {
        switch state {
        case .cancelled:
            Label(String(localized: "Clase cancelada"), systemImage: "xmark.circle")
                .font(Theme.body(18, weight: .semibold))
                .foregroundStyle(Theme.coral)
        case .completed:
            Label(String(localized: "Realizada"), systemImage: "checkmark.circle")
                .font(Theme.body(18, weight: .semibold))
                .foregroundStyle(Theme.lime)
        case .scheduled:
            EmptyView()
        }
    }

    private func actionLabel(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(Theme.body(19, weight: .bold))
            .foregroundStyle(Theme.lime)
            .buttonStyle(.plain)
    }

    private func infoRow<Trailing: View>(
        title: String, subtitle: String, titleColor: Color = Theme.textPrimary, @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.body(22, weight: .semibold)).foregroundStyle(titleColor)
                Text(subtitle).font(Theme.body(17)).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }

    private var dateLine: String {
        let long = DateText.longDate(session.startsAt, calendar: calendar)
        if calendar.isDateInToday(session.startsAt) { return String(localized: "Hoy, \(long)") }
        if calendar.isDateInTomorrow(session.startsAt) { return String(localized: "Mañana, \(long)") }
        return long.prefix(1).uppercased() + long.dropFirst()
    }

    private var planLabel: String {
        String(localized: "Plan \(UserFacingText.planType(session.planType).lowercased())")
    }

    private var orderLabel: String {
        guard let order = session.sourceSlot?.order, let perWeek = session.planPeriod?.classesPerWeek else {
            return String(localized: "Clase adicional")
        }
        return String(localized: "Clase \(order) de \(perWeek) de la semana")
    }

    /// Names of the other clients booked at the same time.
    private func sharingPartners() -> [String] {
        let start = session.startsAt
        let ownID = session.id
        let predicate = #Predicate<ClassSession> { $0.startsAt == start && $0.id != ownID }
        let others = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
        return others.filter { $0.status != .cancelled }.compactMap { $0.client?.fullName }
    }
}
