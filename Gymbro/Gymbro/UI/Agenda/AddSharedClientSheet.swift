import SwiftUI
import SwiftData

/// Adds a second shared client to a shared class that has room.
struct AddSharedClientSheet: View {
    let session: ClassSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.fullName) private var clients: [Client]
    @State private var errorMessage: String?

    private var candidates: [Client] {
        clients.filter {
            $0.isActive && $0.id != session.client?.id && $0.activePeriod(on: session.startsAt)?.planType == .shared
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: String(localized: "Agregar \(Terminology.clientSingular)")) { dismiss() }
            if candidates.isEmpty {
                Text(String(localized: "No hay \(Terminology.clientsTitle.lowercased()) con plan compartido vigente en esa fecha."))
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(20)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(candidates) { client in
                            Button { add(client) } label: {
                                HStack {
                                    Text(client.fullName).font(Theme.body(19)).foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "plus").foregroundStyle(Theme.lime)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            CardDivider()
                        }
                    }
                    .cardBackground()
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert(String(localized: "No se pudo agregar"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func add(_ client: Client) {
        do {
            try SessionBookingService(context: modelContext).book(client: client, at: session.startsAt)
            dismiss()
        } catch {
            errorMessage = UserFacingText.text(for: error)
        }
    }
}
