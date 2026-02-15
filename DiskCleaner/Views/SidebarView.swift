import SwiftUI

struct SidebarView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        @Bindable var appVM = appVM

        List(selection: $appVM.selectedSidebarItem) {
            Section {
                HStack(spacing: 8) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 28, height: 28)
                    Text("DiskCleaner")
                        .font(.headline)
                }
                .padding(.vertical, 2)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section("Disk") {
                Label {
                    VStack(alignment: .leading) {
                        Text(appVM.accessMode.rawValue)
                        if let result = appVM.scanVM.scanResult {
                            Text(result.root.formattedSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(scanTimestamp(result))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } icon: {
                    Image(systemName: appVM.accessMode.icon)
                }
                .tag(SidebarItem.disk)
            }

            if appVM.hasRestrictedDirectories {
                Section("Permissions") {
                    Label {
                        HStack {
                            Text("Directory Access")
                            Spacer()
                            Text("\(appVM.scanVM.restrictedDirectories.count)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.2), in: Capsule())
                        }
                    } icon: {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundStyle(.orange)
                    }
                    .tag(SidebarItem.permissions)
                }
            }

            if appVM.hasHiddenNodes {
                Section("Hidden") {
                    Label {
                        HStack {
                            Text("Hidden Items")
                            Spacer()
                            Text("\(appVM.hiddenNodes.count)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.fill.tertiary, in: Capsule())
                        }
                    } icon: {
                        Image(systemName: "eye.slash")
                    }
                    .tag(SidebarItem.hiddenItems)
                }
            }

            Section("Applications") {
                Label {
                    HStack {
                        Text("App Uninstaller")
                        Spacer()
                        if !appVM.uninstallerVM.apps.isEmpty {
                            Text("\(appVM.uninstallerVM.apps.count)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.fill.tertiary, in: Capsule())
                        }
                    }
                } icon: {
                    Image(systemName: "trash.square")
                }
                .tag(SidebarItem.apps)
            }

            Section("Smart Suggestions") {
                if appVM.suggestionsVM.isDetecting {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Detecting...")
                            .foregroundStyle(.secondary)
                    }
                } else if appVM.suggestionsVM.suggestions.isEmpty {
                    if appVM.scanVM.scanResult != nil {
                        Text("No suggestions found")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        Text("Scan first to see suggestions")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } else {
                    ForEach(groupedSuggestions, id: \.0) { category, suggestions in
                        Label {
                            HStack {
                                Text(category.rawValue)
                                Spacer()
                                Text(formattedSize(for: suggestions))
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.fill.tertiary, in: Capsule())
                            }
                        } icon: {
                            Image(systemName: category.icon)
                                .foregroundStyle(category.riskLevel == .safe ? .green : .orange)
                        }
                        .tag(SidebarItem.suggestion(category))
                    }
                }
            }

            if !appVM.suggestionsVM.suggestions.isEmpty {
                Section {
                    HStack {
                        Text("Total reclaimable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(appVM.suggestionsVM.formattedTotalWaste)
                            .font(.caption.bold())
                    }
                }
            }
            Section("History") {
                Label {
                    HStack {
                        Text("Trash History")
                        Spacer()
                        if !appVM.trashHistory.isEmpty {
                            Text("\(appVM.trashHistory.count)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.fill.tertiary, in: Capsule())
                        }
                    }
                } icon: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .tag(SidebarItem.history)
            }

            Section("Settings") {
                Toggle("Auto-scan on launch", isOn: $appVM.autoScanEnabled)
                    .font(.caption)

                if appVM.autoScanEnabled {
                    HStack {
                        Text("Delay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $appVM.autoScanDelay) {
                            Text("0s").tag(0)
                            Text("3s").tag(3)
                            Text("5s").tag(5)
                            Text("10s").tag(10)
                        }
                        .pickerStyle(.menu)
                        .fixedSize()
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 250)
    }

    private var groupedSuggestions: [(SpaceWasterCategory, [SpaceWaster])] {
        let grouped = Dictionary(grouping: appVM.suggestionsVM.suggestions) { $0.category }
        return SpaceWasterCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    private func formattedSize(for suggestions: [SpaceWaster]) -> String {
        let total = suggestions.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    private func scanTimestamp(_ result: ScanResult) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relative = formatter.localizedString(for: result.scanDate, relativeTo: Date())
        let duration = String(format: "%.1fs", result.duration)
        return "\(relative) (\(duration))"
    }
}
