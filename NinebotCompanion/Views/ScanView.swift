import SwiftUI

struct ScanView: View {
    @EnvironmentObject private var bluetooth: BluetoothManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                switch bluetooth.connectionState {
                case .poweredOff:
                    infoPane(icon: "bluetooth.slash",
                             title: "Bluetooth désactivé",
                             message: "Active le Bluetooth dans les Réglages iOS pour détecter ta trottinette.")
                case .connecting:
                    ProgressView("Connexion…").padding(.top, 60)
                    Spacer()
                case .failed(let reason):
                    infoPane(icon: "exclamationmark.triangle",
                             title: "Échec",
                             message: reason)
                    Spacer()
                default:
                    list
                }
            }
            .navigationTitle("Ninebot Companion")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        bluetooth.startScan()
                    } label: {
                        Label("Scanner", systemImage: "arrow.clockwise")
                    }
                }
            }
            .onAppear { bluetooth.startScan() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "scooter")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Sélectionne ta trottinette")
                .font(.headline)
            if bluetooth.connectionState == .scanning {
                Label("Recherche en cours…", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 24)
    }

    private var list: some View {
        List {
            if bluetooth.discovered.isEmpty {
                Text("Aucun appareil pour l'instant. Assure-toi que la trottinette est allumée et proche.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            ForEach(bluetooth.discovered) { scooter in
                Button {
                    bluetooth.connect(scooter)
                } label: {
                    HStack {
                        Image(systemName: "scooter")
                        VStack(alignment: .leading) {
                            Text(scooter.name).font(.body)
                            Text("Signal \(scooter.rssi) dBm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func infoPane(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40)).foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }
}
