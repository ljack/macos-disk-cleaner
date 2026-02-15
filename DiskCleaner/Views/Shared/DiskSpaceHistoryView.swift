import Charts
import SwiftUI

struct DiskSpaceHistoryView: View {
    let history: DiskSpaceHistory
    let currentFree: Int64

    private var snapshots: [DiskSpaceSnapshot] { history.snapshots }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Free Space History")
                .font(.headline)

            if snapshots.count < 2 {
                ContentUnavailableView(
                    "Not Enough Data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("History will appear as more snapshots are recorded.")
                )
                .frame(width: 360, height: 180)
            } else {
                chart
                    .frame(width: 360, height: 180)
            }

            footer
        }
        .padding()
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(snapshots) { snap in
            AreaMark(
                x: .value("Date", snap.date),
                y: .value("Free", snap.freeBytes)
            )
            .foregroundStyle(gradient)
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Date", snap.date),
                y: .value("Free", snap.freeBytes)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let bytes = value.as(Int64.self) {
                        Text(formatBytes(bytes))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if let first = snapshots.first {
                Text("Since \(first.date, format: .dateTime.month(.abbreviated).day().year())")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(snapshots.count) data points")
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
