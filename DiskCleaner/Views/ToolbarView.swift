import SwiftUI

struct ToolbarView: ToolbarContent {
    @Environment(AppViewModel.self) private var appVM

    var body: some ToolbarContent {
        // Prominent scan button — leftmost, always visible
        ToolbarItem(placement: .navigation) {
            ScanButtonView(style: .toolbar)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            // View mode toggle
            Picker("View", selection: Bindable(appVM).viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Divider()

            // Scan folder selector
            Menu {
                Button {
                    appVM.chooseScanFolder()
                } label: {
                    Label("Choose Folder...", systemImage: "folder.badge.plus")
                }

                if !appVM.bookmarkService.savedLocations.isEmpty {
                    Divider()
                    ForEach(appVM.bookmarkService.savedLocations) { location in
                        Button {
                            appVM.switchToSavedLocation(location)
                        } label: {
                            Label(location.name, systemImage: "folder")
                        }
                    }
                }
            } label: {
                Label(appVM.scanRootName, systemImage: "folder")
            }
            .help("Choose which folder to scan")

            // Delete selected
            if !appVM.selectedNodes.isEmpty {
                Divider()

                Button {
                    appVM.confirmDeletion()
                } label: {
                    Label("Delete \(appVM.selectedNodes.count) items", systemImage: "trash")
                }
                .tint(.red)
            }
        }

        // Disk space bar (click to show history)
        ToolbarItem(placement: .status) {
            if let info = appVM.diskSpaceInfo {
                Button {
                    appVM.showingDiskSpaceHistory.toggle()
                } label: {
                    HStack(spacing: 6) {
                        GeometryReader { geo in
                            let usedFraction = CGFloat(info.used) / CGFloat(info.total)
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.quaternary)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(usedFraction > 0.9 ? .red : .blue)
                                    .frame(width: geo.size.width * usedFraction)
                            }
                        }
                        .frame(width: 80, height: 8)

                        Text("\(ByteCountFormatter.string(fromByteCount: info.free, countStyle: .file)) free")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("Click to show disk space history")
                .popover(isPresented: Bindable(appVM).showingDiskSpaceHistory) {
                    DiskSpaceHistoryView(
                        history: appVM.diskSpaceHistory,
                        currentFree: info.free
                    )
                    .onAppear {
                        appVM.refreshDiskSpace()
                    }
                }
            }
        }
    }
}
