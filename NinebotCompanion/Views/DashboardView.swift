import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var bluetooth: BluetoothManager

    private var s: ScooterState { bluetooth.state }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    speedGauge

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                              spacing: 16) {
                        metric("Batterie", value: s.batteryPercent.map { "\($0) %" },
                               icon: "battery.75", tint: .green)
                        metric("Tension", value: s.batteryVoltage.map { String(format: "%.1f V", $0) },
                               icon: "bolt.fill", tint: .yellow)
                        metric("Distance totale", value: s.totalDistance.map { String(format: "%.1f km", $0) },
                               icon: "map", tint: .blue)
                        metric("Température", value: s.controllerTemperature.map { "\($0) °C" },
                               icon: "thermometer.medium", tint: .orange)
                    }

                    identityCard
                }
                .padding()
            }
            .navigationTitle("Tableau de bord")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        bluetooth.disconnect()
                    } label: {
                        Label("Déconnexion", systemImage: "xmark.circle")
                    }
                }
            }
        }
    }

    private var speedGauge: some View {
        VStack(spacing: 4) {
            Text(s.speed.map { String(format: "%.1f", $0) } ?? "--")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("km/h")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private func metric(_ title: String, value: String?, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value ?? "--")
                .font(.title2.bold())
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            Circle().fill(tint).frame(width: 8, height: 8).padding(10)
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            row("Modèle", bluetooth.model.rawValue)
            row("N° de série", s.serialNumber ?? "—")
            row("Firmware", s.firmwareVersion ?? "—")
            row("Région", s.region.map { "\($0.flagEmoji) \($0.displayName)" } ?? "—")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.callout)
    }
}
