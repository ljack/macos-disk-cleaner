import SwiftUI

/// Prominent scan button with status icon and label.
/// Used both in the toolbar (compact) and empty state (large).
struct ScanButtonView: View {
    @Environment(AppViewModel.self) private var appVM
    let style: ScanButtonStyle

    enum ScanButtonStyle {
        case toolbar   // Compact for toolbar
        case hero      // Large for empty state
    }

    private var status: ScanStatus {
        appVM.scanVM.status
    }

    var body: some View {
        switch style {
        case .toolbar:
            toolbarButton
        case .hero:
            heroButton
        }
    }

    // MARK: - Toolbar compact button

    private var toolbarButton: some View {
        Button {
            handleTap()
        } label: {
            HStack(spacing: 6) {
                statusIcon
                    .frame(width: 16, height: 16)

                Text(status.label)
                    .font(.callout.weight(.medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(buttonTint)
        .help(status.subtitle ?? status.label)
    }

    // MARK: - Hero large button (empty state)

    private var heroButton: some View {
        VStack(spacing: 20) {
            Button {
                handleTap()
            } label: {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(buttonTint.gradient)
                            .frame(width: 72, height: 72)

                        if status == .scanning {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)
                        } else {
                            Image(systemName: status.icon)
                                .font(.system(size: 30))
                                .foregroundStyle(.white)
                        }
                    }

                    Text(status.label)
                        .font(.title3.weight(.semibold))

                    if let subtitle = status.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            // Scanning progress inline
            if status == .scanning, let progress = appVM.scanVM.progress {
                VStack(spacing: 6) {
                    HStack(spacing: 16) {
                        Label("\(progress.filesScanned)", systemImage: "doc")
                        Label("\(progress.directoriesScanned)", systemImage: "folder")
                        Text(ByteCountFormatter.string(fromByteCount: progress.bytesScanned, countStyle: .file))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text(progress.currentPath)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .frame(maxWidth: 400)

                    Button("Stop") {
                        appVM.stopScan()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .transition(.opacity)
            }

            // Scan result summary after completion
            if let result = appVM.scanVM.scanResult, !appVM.scanVM.isScanning {
                HStack(spacing: 16) {
                    Label(result.root.formattedSize, systemImage: "internaldrive")
                    Label("\(result.totalFiles) files", systemImage: "doc")
                    Text(String(format: "%.1fs", result.duration))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: status)
    }

    // MARK: - Shared logic

    @ViewBuilder
    private var statusIcon: some View {
        if status == .scanning {
            ProgressView()
                .controlSize(.small)
        } else {
            Image(systemName: status.icon)
        }
    }

    private var buttonTint: Color {
        switch status {
        case .readyToScan:    return .accentColor
        case .scanning:       return .orange
        case .complete:       return .green
        case .resultsAging:   return .yellow
        case .outdated:       return .orange
        case .stopped:        return .secondary
        case .failed:         return .red
        }
    }

    private func handleTap() {
        if status.canStopScan {
            appVM.stopScan()
        } else if status.canStartScan {
            appVM.startScan()
        }
    }
}
