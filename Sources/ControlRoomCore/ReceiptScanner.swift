import Foundation

public struct ReceiptScanner: Sendable {
    public init() {}
    public func scan(roots: [String], limit: Int = 8) -> [Receipt] {
        var found: [Receipt] = []; let fm = FileManager.default
        for root in roots where fm.fileExists(atPath: root) {
            guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: root), includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { continue }
            for case let url as URL in enumerator {
                let lower = url.lastPathComponent.lowercased()
                guard lower.contains("receipt") || lower.contains("handoff") || lower.contains("release") else { continue }
                guard ["md", "txt", "json"].contains(url.pathExtension.lowercased()) else { continue }
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                found.append(Receipt(title: url.lastPathComponent, path: url.path, timestamp: values?.contentModificationDate ?? .distantPast))
            }
        }
        return found.sorted { $0.timestamp > $1.timestamp }.prefix(limit).map { $0 }
    }
}
