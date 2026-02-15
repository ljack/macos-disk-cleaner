import SwiftUI

@main
struct DiskCleanerApp: App {
    @State private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(appVM)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)
    }
}
