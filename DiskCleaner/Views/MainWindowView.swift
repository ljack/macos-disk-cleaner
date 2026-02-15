import SwiftUI

struct MainWindowView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        @Bindable var appVM = appVM

        NavigationSplitView {
            SidebarView()
        } detail: {
            detailContent
        }
        .toolbar {
            ToolbarView()
        }
        .sheet(isPresented: $appVM.showingDeleteConfirmation) {
            ConfirmationSheet()
        }
        .onChange(of: appVM.scanVM.isScanning) { wasScanning, isScanning in
            if wasScanning && !isScanning && appVM.scanVM.scanResult != nil {
                appVM.onScanComplete()
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        let hasResults = appVM.scanVM.rootNode != nil

        if hasResults {
            // Show results in chosen view mode
            switch appVM.viewMode {
            case .list:
                FileTreeView(root: appVM.scanVM.rootNode!)
            case .treemap:
                if let root = appVM.displayedRoot {
                    TreemapContainerView(root: root)
                }
            }
        } else {
            // Empty state — prominent hero scan button
            VStack {
                Spacer()
                ScanButtonView(style: .hero)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
