import SwiftUI

struct AppListView: View {
    @Environment(AppViewModel.self) private var appVM

    private var uninstallerVM: AppUninstallerViewModel {
        appVM.uninstallerVM
    }

    var body: some View {
        @Bindable var vm = uninstallerVM

        HSplitView {
            // Left: app list
            VStack(spacing: 0) {
                // Search and sort bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search apps...", text: $vm.searchText)
                        .textFieldStyle(.plain)

                    Picker("Sort", selection: $vm.sortOrder) {
                        ForEach(AppSortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize()
                }
                .padding(10)

                Divider()

                if uninstallerVM.isScanning {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                        Text("Discovering apps...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if uninstallerVM.displayedApps.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "app.dashed")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No apps found")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List(uninstallerVM.displayedApps, selection: $vm.selectedApp) { app in
                        AppRowView(app: app)
                            .tag(app)
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 300, idealWidth: 350)

            // Right: detail
            if let app = uninstallerVM.selectedApp {
                AppDetailView(app: app)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "app")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Select an app")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if uninstallerVM.apps.isEmpty && !uninstallerVM.isScanning {
                uninstallerVM.discoverApps()
            }
        }
    }
}

// MARK: - App Row

struct AppRowView: View {
    let app: InstalledApp

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .lineLimit(1)
                if let bundleId = app.bundleIdentifier {
                    Text(bundleId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(app.formattedTotalSize)
                    .font(.callout.monospacedDigit())
                if app.associatedSize > 0 {
                    Text("+\(app.formattedAssociatedSize) data")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
