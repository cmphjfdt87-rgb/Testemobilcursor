import SwiftUI

/// Top-level navigation. Shows the scan screen until a scooter is connected,
/// then reveals the tabbed control interface.
struct RootView: View {
    @EnvironmentObject private var bluetooth: BluetoothManager

    var body: some View {
        Group {
            if bluetooth.connectionState == .connected {
                MainTabView()
            } else {
                ScanView()
            }
        }
        .animation(.easeInOut, value: bluetooth.connectionState)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Tableau de bord", systemImage: "speedometer") }

            RegionView()
                .tabItem { Label("Région", systemImage: "globe.europe.africa") }

            TuningView()
                .tabItem { Label("Réglages", systemImage: "slider.horizontal.3") }

            InfoView()
                .tabItem { Label("Infos", systemImage: "info.circle") }
        }
    }
}
