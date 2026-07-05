import SwiftUI

struct RegionView: View {
    @EnvironmentObject private var bluetooth: BluetoothManager
    @State private var pendingRegion: ScooterRegion?
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ScooterRegion.allCases) { region in
                        Button {
                            pendingRegion = region
                            showConfirm = true
                        } label: {
                            HStack {
                                Text(region.flagEmoji).font(.title2)
                                VStack(alignment: .leading) {
                                    Text(region.displayName).foregroundStyle(.primary)
                                    Text(region.speedNote)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if bluetooth.state.region == region {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Région de la trottinette")
                } footer: {
                    Text("La région définit le plafond de vitesse par défaut et les unités d'affichage. La valeur exacte du registre dépend du firmware — l'app relit toujours la région après écriture pour confirmer.")
                }

                Section {
                    Label("Retirer le limiteur peut rendre la trottinette non homologuée pour la voie publique et annuler la garantie. À utiliser sur terrain privé.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("Région")
            .confirmationDialog("Changer la région ?",
                                isPresented: $showConfirm,
                                titleVisibility: .visible) {
                if let region = pendingRegion {
                    Button("Appliquer \(region.displayName)") {
                        bluetooth.setRegion(region)
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text(pendingRegion?.speedNote ?? "")
            }
        }
    }
}
