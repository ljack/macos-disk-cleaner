import AppKit
import SwiftUI

struct PermissionsView: View {
    @Environment(AppViewModel.self) private var appVM

    private var restrictedDirs: [FileNode] {
        appVM.scanVM.restrictedDirectories
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Directory Permissions")
                        .font(.headline)
                    Text("\(restrictedDirs.count) \(restrictedDirs.count == 1 ? "directory needs" : "directories need") attention")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            if restrictedDirs.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.green)
                    Text("All directories accessible")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                // Directory list
                List {
                    ForEach(restrictedDirs, id: \.id) { node in
                        directoryRow(node)
                    }
                }
                .listStyle(.inset)

                Divider()

                // Footer actions
                HStack {
                    Spacer()
                    Button {
                        grantAllRestricted()
                    } label: {
                        Label("Grant All", systemImage: "shield.checkered")
                    }
                    .buttonStyle(.bordered)
                    .disabled(appVM.scanVM.isResolvingDirectory)
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func directoryRow(_ node: FileNode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.body.weight(.medium))
                Text(node.url.path)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if node.isPermissionDenied {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text("No Access")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.red.opacity(0.1), in: Capsule())
            }

            Button("Grant Access") {
                appVM.grantAccessToDirectory(node)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(appVM.scanVM.isResolvingDirectory)
        }
        .padding(.vertical, 4)
    }

    private func grantAllRestricted() {
        for node in restrictedDirs {
            appVM.grantAccessToDirectory(node)
        }
    }
}

struct ExclusionsView: View {
    @Environment(AppViewModel.self) private var appVM

    @State private var selectedDirectoryURL: URL?
    @State private var newRuleRemainingScans = 3

    private var sortedRules: [ExcludedDirectoryRule] {
        appVM.exclusionRules.sorted { lhs, rhs in
            if lhs.isActive != rhs.isActive {
                return lhs.isActive && !rhs.isActive
            }
            if lhs.remainingScans != rhs.remainingScans {
                return lhs.remainingScans > rhs.remainingScans
            }
            return lhs.path.localizedCaseInsensitiveCompare(rhs.path) == .orderedAscending
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            addRulePanel
            Divider()
            rulesList
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Image(systemName: "minus.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto Excluded Directories")
                    .font(.headline)
                Text("\(appVM.activeExclusionRuleCount) active of \(appVM.exclusionRules.count) total rules")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Scan Now") {
                appVM.startScan()
            }
            .buttonStyle(.bordered)
            .disabled(appVM.scanVM.isScanning)
        }
        .padding()
    }

    @ViewBuilder
    private var addRulePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add or Update Rule")
                .font(.subheadline.weight(.semibold))

            HStack {
                Text(selectedDirectoryURL?.path ?? "No directory selected")
                    .font(.caption)
                    .foregroundStyle(selectedDirectoryURL == nil ? .tertiary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Choose Folder...") {
                    chooseDirectory()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Stepper(value: $newRuleRemainingScans, in: 1...500) {
                    Text("Apply for \(newRuleRemainingScans) scan\(newRuleRemainingScans == 1 ? "" : "s")")
                        .font(.caption)
                }
                .frame(maxWidth: 260, alignment: .leading)

                Spacer()

                Button("Save Rule") {
                    saveRule()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedDirectoryURL == nil)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var rulesList: some View {
        if sortedRules.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 30))
                    .foregroundStyle(.tertiary)
                Text("No exclusion rules yet")
                    .foregroundStyle(.secondary)
                Text("Use \"Choose Folder...\" to add a directory and how many successful scans to skip it.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List {
                ForEach(sortedRules, id: \.id) { rule in
                    exclusionRuleRow(rule)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    @ViewBuilder
    private func exclusionRuleRow(_ rule: ExcludedDirectoryRule) -> some View {
        let remaining = appVM.exclusionRule(for: rule.id)?.remainingScans ?? rule.remainingScans

        HStack(spacing: 12) {
            Image(systemName: "folder.badge.minus")
                .foregroundStyle(rule.isActive ? .orange : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(URL(fileURLWithPath: rule.path).lastPathComponent)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(rule.path)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 8) {
                    Text("Matched \(rule.totalMatches)x")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let lastMatchedAt = rule.lastMatchedAt {
                        Text("Last \(relativeDate(lastMatchedAt))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Stepper(value: remainingBinding(for: rule), in: 0...500) {
                if remaining > 0 {
                    Text("\(remaining) left")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, alignment: .leading)

            Button {
                appVM.removeExclusionRule(id: rule.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Remove rule")
        }
        .padding(.vertical, 4)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Choose a directory to auto-exclude from scans."

        if panel.runModal() == .OK, let url = panel.url {
            selectedDirectoryURL = url
        }
    }

    private func saveRule() {
        guard let directory = selectedDirectoryURL else { return }
        appVM.addExclusionRule(
            for: directory,
            remainingScans: newRuleRemainingScans
        )
    }

    private func remainingBinding(for rule: ExcludedDirectoryRule) -> Binding<Int> {
        Binding(
            get: { appVM.exclusionRule(for: rule.id)?.remainingScans ?? rule.remainingScans },
            set: { appVM.setExclusionRuleRemainingScans(id: rule.id, to: max(0, $0)) }
        )
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
