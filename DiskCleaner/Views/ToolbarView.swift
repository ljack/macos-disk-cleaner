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

            // Access mode
            Button {
                appVM.toggleAccessMode()
            } label: {
                Label(appVM.accessMode.rawValue, systemImage: appVM.accessMode.icon)
            }
            .help(appVM.accessMode == .userDirectory
                  ? "Scanning home directory. Click for full disk."
                  : "Scanning full disk. Click for home directory only.")

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

        // Disk space bar
        ToolbarItem(placement: .status) {
            if let info = appVM.diskSpaceInfo {
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
        }
    }
}
