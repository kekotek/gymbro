import SwiftUI
import SwiftData

/// Registers a new InBody measurement.
struct InBodyFormView: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var date = Date.now
    @State private var weightText = ""
    @State private var fatText = ""
    @State private var muscleText = ""

    private var isValid: Bool { NumberParsing.double(weightText) != nil }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: String(localized: "Nueva medición")) { dismiss() }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FormRow(label: String(localized: "Fecha")) {
                        DatePicker("", selection: $date, in: ...Date.now, displayedComponents: .date)
                            .labelsHidden()
                            .tint(Theme.lime)
                            .environment(\.locale, Locale(identifier: "es_CL"))
                    }
                    CardDivider()
                    FormRow(label: String(localized: "Peso (kg)")) {
                        TextField("0,0", text: $weightText).gymbroTextField().keyboardType(.decimalPad).frame(width: 100)
                    }
                    CardDivider()
                    FormRow(label: String(localized: "Grasa (%)")) {
                        TextField("0,0", text: $fatText).gymbroTextField().keyboardType(.decimalPad).frame(width: 100)
                    }
                    CardDivider()
                    FormRow(label: String(localized: "Músculo (kg)")) {
                        TextField("0,0", text: $muscleText).gymbroTextField().keyboardType(.decimalPad).frame(width: 100)
                    }
                }
                .cardBackground()
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
        let measurement = InBodyMeasurement(
            date: date,
            weightKg: weight,
            bodyFatPercent: NumberParsing.double(fatText),
            muscleMassKg: NumberParsing.double(muscleText)
        )
        modelContext.insert(measurement)
        client.recordMeasurement(measurement)
        dismiss()
    }
}
