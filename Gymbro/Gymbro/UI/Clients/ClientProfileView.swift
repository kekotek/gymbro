import SwiftUI
import SwiftData
import Charts

/// Screen 06: client profile with plan, weekly slots and InBody history.
struct ClientProfileView: View {
    let client: Client
    var backTitle: String = Terminology.clientsTitle
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showRenewal = LaunchOptions.sheet == "renewal"
    @State private var editingSlot: WeeklySlot?
    @State private var showNewSlot = false
    @State private var showNewMeasurement = false
    private let calendar = Calendar.gymbro()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            content(now: timeline.date)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEdit) { ClientFormView(client: client) }
        .sheet(isPresented: $showRenewal) { PlanRenewalView(client: client) }
        .sheet(item: $editingSlot) { slot in WeeklySlotFormView(client: client, slot: slot) }
        .sheet(isPresented: $showNewSlot) { WeeklySlotFormView(client: client, slot: nil) }
        .sheet(isPresented: $showNewMeasurement) { InBodyFormView(client: client) }
    }

    private func content(now: Date) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold))
                            Text(backTitle)
                        }
                    }
                    Spacer()
                    Button(String(localized: "Editar")) { showEdit = true }
                }
                .font(Theme.body(20, weight: .semibold))
                .foregroundStyle(Theme.lime)
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(client.fullName)
                        .font(Theme.display(44))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(String(localized: "\(client.age(on: now, calendar: calendar)) años · \(DateText.fullDate(client.birthDate, calendar: calendar))"))
                        .font(Theme.body(19))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(String(localized: "Plan"))
                    planCard(now: now)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(String(localized: "Horario fijo"))
                    WeeklySlotList(client: client, onEdit: { editingSlot = $0 }, onAdd: { showNewSlot = true })
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SectionLabel(inBodyTitle)
                        Spacer()
                        Button(String(localized: "Nueva medición")) { showNewMeasurement = true }
                            .font(Theme.body(18, weight: .semibold))
                            .foregroundStyle(Theme.lime)
                            .buttonStyle(.plain)
                    }
                    inBodyCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
    }

    // MARK: Plan

    private func planCard(now: Date) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let period = client.displayedPeriod(at: now) {
                    Text("\(Text(UserFacingText.planType(period.planType)).foregroundStyle(period.planType == .shared ? Theme.cyan : Theme.lime)) · \(Text(String(localized: "\(period.classCount) clases")).foregroundStyle(Theme.textPrimary))")
                        .font(Theme.body(20, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(periodLine(period, now: now))
                        .font(Theme.body(16))
                        .lineLimit(2)
                        .foregroundStyle(period.endDate <= now ? Theme.coral : Theme.textSecondary)
                } else {
                    Text(String(localized: "Sin plan"))
                        .font(Theme.body(22, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(String(localized: "Renueva para agendar sus clases"))
                        .font(Theme.body(17))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 8)
            Button(String(localized: "Renovar")) { showRenewal = true }
                .font(Theme.body(17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.textPrimary, lineWidth: 1))
                .buttonStyle(.plain)
        }
        .padding(16)
        .cardBackground()
    }

    private func periodLine(_ period: PlanPeriod, now: Date) -> String {
        let lastDay = calendar.date(byAdding: .day, value: -1, to: period.endDate) ?? period.endDate
        let range = "\(DateText.dayAndMonth(period.startDate, calendar: calendar)) – \(DateText.dayAndMonth(lastDay, calendar: calendar))"
        if period.endDate <= now {
            return String(localized: "Venció el \(DateText.shortDayMonth(lastDay, calendar: calendar))")
        }
        if period.startDate > now {
            return String(localized: "Empieza el \(DateText.shortDay(period.startDate, calendar: calendar)) · \(range)")
        }
        return "\(range) · " + String(localized: "van \(period.completedCount(at: now, calendar: calendar)) de \(period.classCount)")
    }

    // MARK: InBody

    private var inBodyTitle: String {
        guard let latest = client.latestMeasurement else { return "InBody" }
        return "InBody · \(DateText.dayAndMonth(latest.date, calendar: calendar))"
    }

    @ViewBuilder
    private var inBodyCard: some View {
        if let latest = client.latestMeasurement {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    metric(String(localized: "Peso"), value: latest.weightKg, unit: "kg")
                    Spacer()
                    metric(String(localized: "Grasa"), value: latest.bodyFatPercent, unit: "%")
                    Spacer()
                    metric(String(localized: "Músculo"), value: latest.muscleMassKg, unit: "kg")
                }
                weightChart
            }
            .padding(16)
            .cardBackground()
        } else {
            Text(String(localized: "Sin mediciones todavía"))
                .font(Theme.body(17))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .cardBackground()
        }
    }

    private func metric(_ label: String, value: Double?, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(Theme.body(16)).foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value.map { DateText.decimal($0) } ?? "–")
                    .font(Theme.display(38))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit).font(Theme.body(15)).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var weightChart: some View {
        let points = client.inBodyMeasurements.sorted { $0.date < $1.date }.suffix(4)
        let last = points.last?.id
        return Chart(Array(points)) { measurement in
            LineMark(x: .value("Fecha", measurement.date), y: .value("Peso", measurement.weightKg))
                .foregroundStyle(Theme.lime)
                .lineStyle(StrokeStyle(lineWidth: 3))
            PointMark(x: .value("Fecha", measurement.date), y: .value("Peso", measurement.weightKg))
                .foregroundStyle(measurement.id == last ? Theme.lime : Theme.surface)
                .symbolSize(140)
                .annotation(position: .top, spacing: 8) {
                    Text(DateText.decimal(measurement.weightKg))
                        .font(Theme.body(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
            PointMark(x: .value("Fecha", measurement.date), y: .value("Peso", measurement.weightKg))
                .foregroundStyle(Theme.lime)
                .symbol(.circle.strokeBorder(lineWidth: 3))
                .symbolSize(140)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: Array(points.map(\.date))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(DateText.dayAndMonth(date, calendar: calendar))
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartPlotStyle { $0.padding(.top, 28).padding(.horizontal, 12) }
        .frame(height: 170)
    }
}
