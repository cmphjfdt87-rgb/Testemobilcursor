import SwiftUI

@main
struct NinebotCompanionApp: App {
    @StateObject private var bluetooth = BluetoothManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(bluetooth)
                .preferredColorScheme(.dark)
        }
    }
}
