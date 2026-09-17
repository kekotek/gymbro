import SwiftUI

/// The "Horario fijo" card: one row per weekly slot plus an add row.
struct WeeklySlotList: View {
    let client: Client
    let onEdit: (WeeklySlot) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(client.sortedWeeklySlots) { slot in
                Button { onEdit(slot) } label: {
                    HStack(spacing: 16) {
                        Text("\((DateText.shortWeekdays[slot.weekday] ?? "").capitalized) \(DateText.timeOfDay(slot.startMinuteOfDay))")
                            .font(Theme.heading(22))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 104, alignment: .leading)
                        Text(slot.routine?.name ?? String(localized: "Sin rutina"))
                            .font(Theme.body(19))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                CardDivider()
            }
            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text(String(localized: "Agregar horario"))
                }
                .font(Theme.body(18, weight: .semibold))
                .foregroundStyle(Theme.lime)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .cardBackground()
    }
}
