import Foundation

/// Persists disk free-space snapshots with automatic time-bucket compaction.
@MainActor
@Observable
final class DiskSpaceHistory {
    private(set) var snapshots: [DiskSpaceSnapshot] = []

    private static let defaultsKey = "diskSpaceHistory"

    init() {
        load()
    }

    func record(freeBytes: Int64) {
        let snapshot = DiskSpaceSnapshot(date: Date(), freeBytes: freeBytes)
        snapshots.append(snapshot)
        compact()
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let decoded = try? JSONDecoder().decode([DiskSpaceSnapshot].self, from: data) else { return }
        snapshots = decoded.sorted { $0.date < $1.date }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    // MARK: - Compaction

    /// Groups snapshots into time buckets based on age and averages each group.
    ///
    /// | Age            | Resolution kept |
    /// |----------------|-----------------|
    /// | Last 24 hours  | Every point     |
    /// | 1–7 days       | 1 per hour      |
    /// | 7–30 days      | 1 per day       |
    /// | 30–365 days    | 1 per week      |
    /// | 1–10 years     | 1 per month     |
    /// | 10+ years      | 1 per year      |
    private func compact() {
        let now = Date()
        let calendar = Calendar.current

        let h24  = now.addingTimeInterval(-24 * 3600)
        let d7   = now.addingTimeInterval(-7 * 24 * 3600)
        let d30  = now.addingTimeInterval(-30 * 24 * 3600)
        let d365 = now.addingTimeInterval(-365 * 24 * 3600)
        let y10  = now.addingTimeInterval(-10 * 365 * 24 * 3600)

        var result: [DiskSpaceSnapshot] = []

        // Recent (< 24h) — keep all
        let recent = snapshots.filter { $0.date >= h24 }
        result.append(contentsOf: recent)

        // 1–7 days — 1 per hour
        let week = snapshots.filter { $0.date >= d7 && $0.date < h24 }
        result.append(contentsOf: bucketAverage(week) { calendar.dateInterval(of: .hour, for: $0.date) })

        // 7–30 days — 1 per day
        let month = snapshots.filter { $0.date >= d30 && $0.date < d7 }
        result.append(contentsOf: bucketAverage(month) { calendar.dateInterval(of: .day, for: $0.date) })

        // 30–365 days — 1 per week
        let year = snapshots.filter { $0.date >= d365 && $0.date < d30 }
        result.append(contentsOf: bucketAverage(year) { calendar.dateInterval(of: .weekOfYear, for: $0.date) })

        // 1–10 years — 1 per month
        let decade = snapshots.filter { $0.date >= y10 && $0.date < d365 }
        result.append(contentsOf: bucketAverage(decade) { calendar.dateInterval(of: .month, for: $0.date) })

        // 10+ years — 1 per year
        let ancient = snapshots.filter { $0.date < y10 }
        result.append(contentsOf: bucketAverage(ancient) { calendar.dateInterval(of: .year, for: $0.date) })

        snapshots = result.sorted { $0.date < $1.date }
    }

    /// Groups snapshots by a calendar bucket, averaging each group into one point.
    private func bucketAverage(
        _ items: [DiskSpaceSnapshot],
        bucket: (DiskSpaceSnapshot) -> DateInterval?
    ) -> [DiskSpaceSnapshot] {
        let grouped = Dictionary(grouping: items) { snap -> Date in
            bucket(snap)?.start ?? snap.date
        }
        return grouped.map { (bucketStart, group) in
            let avgBytes = group.map(\.freeBytes).reduce(0, +) / Int64(group.count)
            let midDate = group[group.count / 2].date
            return DiskSpaceSnapshot(date: midDate, freeBytes: avgBytes)
        }
    }
}

/// Persists temporary directory-exclusion rules used to skip subtrees during scan.
@MainActor
@Observable
final class DirectoryExclusionStore {
    private static let defaultsKey = "directoryExclusionRules"

    private(set) var rules: [ExcludedDirectoryRule] = []

    init() {
        load()
    }

    var activeRuleCount: Int {
        rules.filter(\.isActive).count
    }

    func rule(by id: UUID?) -> ExcludedDirectoryRule? {
        guard let id else { return nil }
        return rules.first { $0.id == id }
    }

    func upsertRule(for directoryURL: URL, remainingScans: Int, scope: ExclusionRuleScope) {
        let normalizedPath = Self.normalizePath(directoryURL)
        guard !normalizedPath.isEmpty else { return }

        if let index = rules.firstIndex(where: {
            $0.normalizedPath == normalizedPath && $0.scope == scope
        }) {
            rules[index].remainingScans = max(0, remainingScans)
        } else {
            let rule = ExcludedDirectoryRule(
                path: normalizedPath,
                remainingScans: remainingScans,
                scope: scope
            )
            rules.append(rule)
        }
        save()
    }

    func upsertRule(path: String, remainingScans: Int, scope: ExclusionRuleScope) {
        upsertRule(for: URL(fileURLWithPath: path), remainingScans: remainingScans, scope: scope)
    }

    func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
        save()
    }

    func setRemainingScans(for id: UUID, to newValue: Int) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index].remainingScans = max(0, newValue)
        save()
    }

    func activeScanRules(for mode: DiskAccessMode) -> [ScanExclusionRule] {
        rules
            .filter { $0.isActive && $0.scope.applies(to: mode) }
            .map { ScanExclusionRule(id: $0.id, normalizedPath: $0.normalizedPath) }
    }

    /// Consume one count for each rule that was encountered in a successful scan.
    func consumeMatchedRules(_ matchedRuleIDs: Set<UUID>) {
        guard !matchedRuleIDs.isEmpty else { return }

        let now = Date()
        var changed = false

        for index in rules.indices {
            guard matchedRuleIDs.contains(rules[index].id) else { continue }
            guard rules[index].remainingScans > 0 else { continue }

            rules[index].remainingScans -= 1
            rules[index].totalMatches += 1
            rules[index].lastMatchedAt = now
            changed = true
        }

        if changed {
            save()
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let decoded = try? JSONDecoder().decode([ExcludedDirectoryRule].self, from: data) else { return }
        rules = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    private static func normalizePath(_ url: URL) -> String {
        url.standardizedFileURL.path
    }
}
