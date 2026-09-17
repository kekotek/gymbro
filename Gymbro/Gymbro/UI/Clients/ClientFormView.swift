import SwiftUI
import SwiftData

/// Create or edit a client. No reference screen; keeps the app's style.
struct ClientFormView: View {
    let client: Client?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var fullName: String
    @State private var birthDate: Date
    @State private var weightText: String
    @State private var planType: PlanType
    private let calendar = Calendar.gymbro()

    init(client: Client?) {
        self.client = client
        _fullName = State(initialValue: client?.fullName ?? "")
        _birthDate = State(initialValue: client?.birthDate ?? Calendar.gymbro().date(byAdding: .year, value: -30, to: .now)!)
        _weightText = State(initialValue: client.map { DateText.decimal($0.weightKg) } ?? "")
        _planType = State(initialValue: client?.planType ?? .individual)
    }

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty && NumberParsing.double(weightText) != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: client == nil ? String(localized: "Nuevo \(Terminology.clientSingular)") : String(localized: "Editar \(Terminology.clientSingular)")) { dismiss() }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 0) {
                        FormRow(label: String(localized: "Nombre")) {
                            TextField(String(localized: "Nombre completo"), text: $fullName)
                                .gymbroTextField()
                                .textInputAutocapitalization(.words)
                        }
                        CardDivider()
                        FormRow(label: String(localized: "Nacimiento")) {
                            DatePicker("", selection: $birthDate, in: ...Date.now, displayedComponents: .date)
                                .labelsHidden()
                                .tint(Theme.lime)
                                .environment(\.locale, Locale(identifier: "es_CL"))
                        }
                        CardDivider()
                        FormRow(label: String(localized: "Peso (kg)")) {
                            TextField("0,0", text: $weightText)
                                .gymbroTextField()
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }
                    }
                    .cardBackground()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Tipo de plan"))
                        SegmentedChoice(selection: $planType, options: [
                            (.individual, UserFacingText.planType(.individual)),
                            (.shared, UserFacingText.planType(.shared)),
                        ])
                        Text(String(localized: "El tipo se confirma en cada renovación."))
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
            }
            Button(String(localized: "Guardar")) { save() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func save() {
        guard let weight = NumberParsing.double(weightText) else { return }
        let name = fullName.trimmingCharacters(in: .whitespaces)
        if let client {
            client.fullName = name
            client.birthDate = birthDate
            client.weightKg = weight
            client.planType = planType
        } else {
            modelContext.insert(Client(fullName: name, birthDate: birthDate, weightKg: weight, planType: planType))
        }
        dismiss()
    }
}

enum NumberParsing {
    /// Accepts "63,4" and "63.4".
    static func double(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }
}
