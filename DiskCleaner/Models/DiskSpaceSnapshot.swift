import Foundation

struct DiskSpaceSnapshot: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let freeBytes: Int64
}
