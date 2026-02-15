import SwiftUI

struct MainWindowView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        @Bindable var appVM = appVM
        @Bindable var uninstallerVM = appVM.uninstallerVM

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
        .sheet(isPresented: $uninstallerVM.showingUninstallConfirmation) {
            UninstallConfirmationSheet()
        }
        .onChange(of: appVM.scanVM.isScanning) { wasScanning, isScanning in
            if wasScanning && !isScanning && appVM.scanVM.scanResult != nil {
                appVM.onScanComplete()
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appVM.selectedSidebarItem {
        case .permissions:
            PermissionsView()
        case .apps:
            AppListView()
        case .history:
            TrashHistoryView()
        case .suggestion(let category):
            SuggestionsListView(category: category)
        case .disk, nil:
            diskContent
        }
    }

    @ViewBuilder
    private var diskContent: some View {
        let hasResults = appVM.scanVM.rootNode != nil

        if hasResults {
            switch appVM.viewMode {
            case .list:
                FileTreeView(root: appVM.scanVM.rootNode!)
            case .treemap:
                if let root = appVM.displayedRoot {
                    TreemapContainerView(root: root)
                }
            }
        } else {
            VStack {
                Spacer()
                ScanButtonView(style: .hero)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
