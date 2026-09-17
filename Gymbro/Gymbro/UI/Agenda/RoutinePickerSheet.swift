import SwiftUI
import SwiftData

/// Picks a routine from the catalog or creates a new one.
struct RoutinePickerSheet: View {
    let selected: Routine?
    let onSelect: (Routine) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var newName = ""

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: String(localized: "Rutina")) { dismiss() }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(routines) { routine in
                        Button {
                            onSelect(routine)
                            dismiss()
                        } label: {
                            HStack {
                                Text(routine.name).font(Theme.body(19)).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if routine.id == selected?.id {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.lime)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        CardDivider()
                    }
                    HStack {
                        TextField(String(localized: "Nueva rutina"), text: $newName)
                            .font(Theme.body(18))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.lime)
                        Button(String(localized: "Agregar")) { addRoutine() }
                            .font(Theme.body(18, weight: .bold))
                            .foregroundStyle(Theme.lime)
                            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                }
                .cardBackground()
                .padding(.horizontal, 20)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func addRoutine() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let routine = Routine(name: name)
        modelContext.insert(routine)
        onSelect(routine)
        dismiss()
    }
}
