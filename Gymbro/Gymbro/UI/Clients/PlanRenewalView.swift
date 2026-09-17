import SwiftUI
import SwiftData

/// Screen 07: renew the monthly plan and generate its classes.
struct PlanRenewalView: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var planType: PlanType
    @State private var classCount: Int
    @State private var editingSlot: WeeklySlot?
    @State private var showNewSlot = false
    @State private var errorMessage: String?
    private let calendar = Calendar.gymbro()
    private let now = Date.now

    init(client: Client) {
        self.client = client
        _planType = State(initialValue: client.latestPeriod?.planType ?? client.planType)
        _classCount = State(initialValue: client.latestPeriod?.classCount ?? 12)
    }

    private var classesPerWeek: Int { PlanPeriodRules.classesPerWeek(for: classCount) }
    private var slotCount: Int { client.weeklySlots.count }
    private var startDate: Date {
        PlanPeriodRules.startDate(forRenewalOn: now, existingPeriods: client.planPeriods.map(\.interval), calendar: calendar)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: String(localized: "Renovar plan")) { dismiss() }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    clientCard
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Tipo de plan"))
                        SegmentedChoice(selection: $planType, options: [
                            (.individual, UserFacingText.planType(.individual)),
                            (.shared, UserFacingText.planType(.shared)),
                        ])
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Clases del mes"))
                        classCountPicker
                        Text(summary)
                            .font(Theme.body(17))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Horario fijo"))
                        WeeklySlotList(client: client, onEdit: { editingSlot = $0 }, onAdd: { showNewSlot = true })
                        if slotCount != classesPerWeek {
                            Text(String(localized: "Necesitas \(classesPerWeek) horarios fijos y tienes \(slotCount)"))
                                .font(Theme.body(16, weight: .semibold))
                                .foregroundStyle(Theme.coral)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            Button(String(localized: "Renovar y agendar \(classCount) clases")) { renew() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(slotCount != classesPerWeek)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(item: $editingSlot) { slot in WeeklySlotFormView(client: client, slot: slot) }
        .sheet(isPresented: $showNewSlot) { WeeklySlotFormView(client: client, slot: nil) }
        .alert(String(localized: "No se pudo renovar"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var clientCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.fullName)
                .font(Theme.body(22, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(currentPlanLine)
                .font(Theme.body(17))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardBackground()
    }

    private var currentPlanLine: String {
        guard let latest = client.latestPeriod, latest.endDate > now,
              let lastDay = calendar.date(byAdding: .day, value: -1, to: latest.endDate) else {
            return String(localized: "Sin plan vigente")
        }
        return String(localized: "Su plan actual termina el \(DateText.shortDayMonth(lastDay, calendar: calendar))")
    }

    private var classCountPicker: some View {
        HStack(spacing: 10) {
            ForEach(GymSchedule.allowedClassCounts.sorted(), id: \.self) { count in
                let selected = count == classCount
                Button { classCount = count } label: {
                    VStack(spacing: 2) {
                        Text("\(count)").font(Theme.display(34))
                        Text(String(localized: "\(PlanPeriodRules.classesPerWeek(for: count)) por sem."))
                            .font(Theme.body(14))
                    }
                    .foregroundStyle(selected ? Theme.onLime : Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 84)
                    .background(RoundedRectangle(cornerRadius: 14).fill(selected ? Theme.lime : Theme.surface))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var summary: String {
        let end = PlanPeriodRules.endDate(for: startDate, calendar: calendar)
        let lastDay = calendar.date(byAdding: .day, value: -1, to: end) ?? end
        return String(localized: "Al renovar se agendan \(classCount) clases entre el \(DateText.shortDayMonth(startDate, calendar: calendar)) y el \(DateText.shortDayMonth(lastDay, calendar: calendar)): \(classesPerWeek) por semana durante \(GymSchedule.periodWeekCount) semanas.")
    }

    private func renew() {
        do {
            try PlanRenewalService(context: modelContext, calendar: calendar)
                .renew(client: client, classCount: classCount, planType: planType, on: now)
            dismiss()
        } catch {
            errorMessage = UserFacingText.text(for: error, calendar: calendar)
        }
    }
}
