import SwiftUI
import SwiftData

/// Create, edit or delete one weekly slot (day, time and routine).
struct WeeklySlotFormView: View {
    let client: Client
    let slot: WeeklySlot?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var weekday: Weekday
    @State private var minute: Int
    @State private var routine: Routine?
    @State private var newRoutineName = ""
    @State private var errorMessage: String?
    private let calendar = Calendar.gymbro()

    init(client: Client, slot: WeeklySlot?) {
        self.client = client
        self.slot = slot
        _weekday = State(initialValue: slot?.weekday ?? .monday)
        _minute = State(initialValue: slot?.startMinuteOfDay ?? 8 * 60)
        _routine = State(initialValue: slot?.routine)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: slot == nil ? String(localized: "Nuevo horario") : String(localized: "Horario fijo")) { dismiss() }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Día"))
                        HStack(spacing: 8) {
                            ForEach(GymSchedule.workingWeekdays.sorted(), id: \.self) { day in
                                let selected = day == weekday
                                Button { weekday = day } label: {
                                    Text((DateText.shortWeekdays[day] ?? "").capitalized)
                                        .font(Theme.heading(18))
                                        .foregroundStyle(selected ? Theme.onLime : Theme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Theme.lime : Theme.surface))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Hora de inicio"))
                        Picker(String(localized: "Hora"), selection: $minute) {
                            ForEach(GymSchedule.allStartMinutes, id: \.self) { start in
                                Text(DateText.timeOfDay(start)).tag(start)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .cardBackground()
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Rutina"))
                        routineList
                    }
                    if let slot {
                        Button(String(localized: "Eliminar horario")) { delete(slot) }
                            .buttonStyle(OutlineButtonStyle(color: Theme.coral, borderColor: Theme.line))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            Button(String(localized: "Guardar")) { save() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert(String(localized: "Atención"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil; dismiss() } })) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var routineList: some View {
        VStack(spacing: 0) {
            ForEach(routines) { item in
                Button { routine = item } label: {
                    HStack {
                        Text(item.name).font(Theme.body(19)).foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if item.id == routine?.id { Image(systemName: "checkmark").foregroundStyle(Theme.lime) }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                CardDivider()
            }
            HStack {
                TextField(String(localized: "Nueva rutina"), text: $newRoutineName)
                    .font(Theme.body(18))
                    .foregroundStyle(Theme.textPrimary)
                    .tint(Theme.lime)
                Button(String(localized: "Agregar")) {
                    let name = newRoutineName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let created = Routine(name: name)
                    modelContext.insert(created)
                    routine = created
                    newRoutineName = ""
                }
                .font(Theme.body(18, weight: .bold))
                .foregroundStyle(Theme.lime)
                .disabled(newRoutineName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
        }
        .cardBackground()
    }

    private func save() {
        if let slot {
            slot.weekday = weekday
            slot.startMinuteOfDay = minute
            slot.routine = routine
        } else {
            let created = WeeklySlot(weekday: weekday, startMinuteOfDay: minute, order: client.weeklySlots.count + 1, routine: routine)
            modelContext.insert(created)
            created.client = client
        }
        syncFuturePeriods()
    }

    private func delete(_ slot: WeeklySlot) {
        modelContext.delete(slot)
        for (index, remaining) in client.sortedWeeklySlots.filter({ $0.id != slot.id }).enumerated() {
            remaining.order = index + 1
        }
        dismiss()
    }

    /// Re-aligns future classes of the current and upcoming periods with the new slot.
    private func syncFuturePeriods() {
        let now = Date.now
        let service = PlanRenewalService(context: modelContext, calendar: calendar)
        var problems: [String] = []
        for period in client.planPeriods where period.endDate > now {
            do {
                try service.syncSessions(for: period, now: now)
            } catch {
                problems.append(UserFacingText.text(for: error, calendar: calendar))
            }
        }
        if problems.isEmpty {
            dismiss()
        } else {
            errorMessage = String(localized: "El horario se guardó, pero las clases ya agendadas no se movieron:\n") + problems.joined(separator: "\n")
        }
    }
}
