import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(20, weight: .semibold))
            .foregroundStyle(Theme.onLime)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.lime))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    var color: Color = Theme.textPrimary
    var borderColor: Color = Theme.textPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(20, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(RoundedRectangle(cornerRadius: 18).strokeBorder(borderColor.opacity(0.9), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Small uppercase section title ("PLAN", "HORARIO FIJO").
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.heading(16))
            .tracking(2)
            .foregroundStyle(Theme.textSecondary)
    }
}

/// Header of a modal sheet: "Cancelar" on the left and the title.
struct SheetHeader: View {
    let title: String
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(Theme.display(28))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 96)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack {
                Button(String(localized: "Cancelar"), action: onCancel)
                    .font(Theme.body(19, weight: .medium))
                    .foregroundStyle(Theme.lime)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

/// Two-option selector styled like the reference segmented controls.
struct SegmentedChoice<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(Value, String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selection = option.0 }
                } label: {
                    Text(option.1)
                        .font(Theme.body(18, weight: selection == option.0 ? .bold : .medium))
                        .foregroundStyle(selection == option.0 ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(selection == option.0 ? Theme.surfaceRaised : .clear))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
    }
}

/// A labeled row inside a form card.
struct FormRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.body(17))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
    }
}

struct CardDivider: View {
    var body: some View {
        Rectangle().fill(Theme.background).frame(height: 1)
    }
}

extension View {
    func cardBackground() -> some View {
        background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
    }

    func gymbroTextField() -> some View {
        font(Theme.body(18))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.trailing)
            .tint(Theme.lime)
    }
}

/// Spanish text for rule failures.
enum UserFacingText {
    static func text(for failure: PlacementFailure) -> String {
        switch failure {
        case .invalidStartMinute: return String(localized: "La hora debe ser en punto o y media")
        case .outsideGymHours: return String(localized: "Fuera del horario del gimnasio")
        case .outsideWorkingDays: return String(localized: "Ese día no se atiende")
        case .noActivePlan: return String(localized: "Sin plan vigente en esa fecha")
        case .sameClientOverlap: return String(localized: "Ya tiene otra clase a esa hora")
        case .blockedByIndividual: return String(localized: "Ocupada por un plan individual")
        case .individualCannotShare: return String(localized: "Hora ocupada")
        case .sharedFull: return String(localized: "Compartida sin cupo")
        case .sharedPartialOverlap: return String(localized: "Se cruza con una clase compartida")
        }
    }

    static func text(for error: Error, calendar: Calendar = .gymbro()) -> String {
        guard let error = error as? SchedulingError else { return error.localizedDescription }
        switch error {
        case .invalidClassCount(let count):
            return String(localized: "\(count) no es una cantidad válida de clases")
        case .slotCountMismatch(let expected, let actual):
            return String(localized: "Necesitas \(expected) horarios fijos y tienes \(actual)")
        case .invalidSlotTime(let weekday, let minute):
            return String(localized: "Horario fijo inválido: \(DateText.shortWeekdays[weekday] ?? "") \(DateText.timeOfDay(minute))")
        case .conflicts(let conflicts):
            let lines = conflicts.prefix(6).map {
                "\(DateText.shortDay($0.startsAt, calendar: calendar)) \(DateText.time($0.startsAt, calendar: calendar)): \(text(for: $0.failure))"
            }
            let more = conflicts.count > 6 ? "\n…" : ""
            return String(localized: "No se guardó nada. Conflictos:\n") + lines.joined(separator: "\n") + more
        case .placementRejected(let failure):
            return text(for: failure)
        case .sessionNotScheduled:
            return String(localized: "Esta clase ya no está pendiente")
        case .missingPlanPeriod:
            return String(localized: "El alumno no tiene plan vigente")
        case .targetOutsidePlanPeriod:
            return String(localized: "La fecha queda fuera del período del plan")
        }
    }

    static func planType(_ type: PlanType) -> String {
        switch type {
        case .individual: return String(localized: "Individual")
        case .shared: return String(localized: "Compartido")
        }
    }
}
