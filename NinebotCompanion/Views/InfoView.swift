import SwiftUI

struct InfoView: View {
    @EnvironmentObject private var bluetooth: BluetoothManager

    var body: some View {
        NavigationStack {
            List {
                Section("Modèle détecté") {
                    Picker("Famille", selection: $bluetooth.model) {
                        ForEach(ScooterModel.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    if bluetooth.model.usesEncryption {
                        Label("Cette famille utilise un protocole chiffré.",
                              systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Journal") {
                    if bluetooth.log.isEmpty {
                        Text("Aucun événement.").foregroundStyle(.secondary)
                    }
                    ForEach(bluetooth.log, id: \.self) { line in
                        Text(line)
                            .font(.caption.monospaced())
                    }
                }

                Section {
                    Text("Ninebot Companion est un outil de diagnostic et de configuration pour trottinettes Ninebot/Xiaomi que tu possèdes. Utilise-le conformément aux lois locales.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Infos")
        }
    }
}
