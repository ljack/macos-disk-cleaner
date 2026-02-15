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
        case .exclusions:
            ExclusionsView()
        case .hiddenItems:
            HiddenItemsView()
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
    private var permissionsBanner: some View {
        if appVM.showPermissionsBanner {
            let count = appVM.scanVM.restrictedDirectories.count
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(.orange)
                Text("\(count) \(count == 1 ? "directory was" : "directories were") skipped")
                    .fontWeight(.medium)
                Text("— Grant access to include them in results")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Review") {
                    appVM.selectedSidebarItem = .permissions
                    appVM.showPermissionsBanner = false
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Button {
                    appVM.showPermissionsBanner = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.orange.opacity(0.1))
        }
    }

    @ViewBuilder
    private var diskContent: some View {
        let hasResults = appVM.scanVM.rootNode != nil

        if hasResults {
            VStack(spacing: 0) {
                permissionsBanner
                switch appVM.viewMode {
                case .list:
                    FileTreeView(root: appVM.scanVM.rootNode!)
                case .treemap:
                    if let root = appVM.displayedRoot {
                        TreemapContainerView(root: root)
                    }
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
