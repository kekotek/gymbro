import SwiftUI

/// Class detail. Actions (reschedule, cancel, mark as done) arrive in the next step.
struct ClassDetailView: View {
    let session: ClassSession
    @Environment(\.dismiss) private var dismiss
    private let calendar = Calendar.gymbro()

    var body: some View {
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
            Text(dateLine)
                .font(Theme.body(20))
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 4)
                .padding(.bottom, 28)

            VStack(spacing: 0) {
                row(title: session.client?.fullName ?? "", subtitle: planLabel)
                divider
                row(title: session.routine?.name ?? String(localized: "Sin rutina"), subtitle: orderLabel)
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))

            if let slot = session.sourceSlot {
                Text(String(localized: "Horario fijo: todos los \(DateText.longWeekdays[slot.weekday] ?? "") a las \(DateText.timeOfDay(slot.startMinuteOfDay))"))
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 20)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var dateLine: String {
        let long = DateText.longDate(session.startsAt, calendar: calendar)
        if calendar.isDateInToday(session.startsAt) {
            return String(localized: "Hoy, \(long)")
        }
        return long.capitalized
    }

    private var planLabel: String {
        switch session.planType {
        case .individual: return String(localized: "Plan individual")
        case .shared: return String(localized: "Plan compartido")
        }
    }

    private var orderLabel: String {
        guard let order = session.sourceSlot?.order, let perWeek = session.planPeriod?.classesPerWeek else { return "" }
        return String(localized: "Clase \(order) de \(perWeek) de la semana")
    }

    private var divider: some View {
        Rectangle().fill(Theme.background).frame(height: 1)
    }

    private func row(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.body(22, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            Text(subtitle).font(Theme.body(17)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }
}
