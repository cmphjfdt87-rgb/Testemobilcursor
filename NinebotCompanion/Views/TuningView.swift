import SwiftUI

struct TuningView: View {
    @EnvironmentObject private var bluetooth: BluetoothManager
    @State private var speedLimit: Double = 25
    @State private var cruise = false
    @State private var tailLight = false
    @State private var acknowledged = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $acknowledged) {
                        Text("J'ai compris les risques (légalité, sécurité, garantie) et j'utilise ces réglages sur terrain privé.")
                            .font(.footnote)
                    }
                } footer: {
                    Text("Les écritures sont désactivées tant que cette case n'est pas cochée.")
                }

                Section("Vitesse maximale") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(Int(speedLimit)) km/h")
                                .font(.title2.bold())
                                .monospacedDigit()
                            Spacer()
                            if let current = bluetooth.state.speedLimit {
                                Text("Actuel: \(current) km/h")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Slider(value: $speedLimit, in: 5...45, step: 1)
                            .disabled(!acknowledged)
                        Button("Appliquer la vitesse") {
                            bluetooth.setSpeedLimit(Int(speedLimit))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!acknowledged)
                    }
                }

                Section("Options") {
                    Toggle("Régulateur de vitesse (cruise)", isOn: $cruise)
                        .disabled(!acknowledged)
                        .onChange(of: cruise) { _, v in bluetooth.setCruiseControl(v) }
                    Toggle("Feu arrière", isOn: $tailLight)
                        .disabled(!acknowledged)
                        .onChange(of: tailLight) { _, v in bluetooth.setTailLight(v) }
                }

                Section {
                    Label("Sur les firmwares chiffrés (Max G30 et plus récents), les écritures nécessitent le schéma de chiffrement vérifié pour ton modèle — voir NinebotCrypto.",
                          systemImage: "lock.shield")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
            .onAppear {
                if let current = bluetooth.state.speedLimit {
                    speedLimit = Double(current)
                }
            }
        }
    }
}
