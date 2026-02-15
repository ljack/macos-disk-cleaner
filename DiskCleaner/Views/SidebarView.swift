import SwiftUI

struct SidebarView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        @Bindable var appVM = appVM

        List(selection: $appVM.selectedSidebarItem) {
            Section("Disk") {
                Label {
                    VStack(alignment: .leading) {
                        Text(appVM.accessMode.rawValue)
                        if let result = appVM.scanVM.scanResult {
                            Text(result.root.formattedSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: appVM.accessMode.icon)
                }
                .tag(SidebarItem.disk)
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
}
