import Foundation

public struct ControlRoomConfig: Codable, Equatable, Sendable {
    public let repoPaths: [String]
    public let receiptRoots: [String]

    public init(repoPaths: [String], receiptRoots: [String]) {
        self.repoPaths = repoPaths
        self.receiptRoots = receiptRoots
    }

    public static let nodaysidleDefault = ControlRoomConfig(
        repoPaths: [
            "/Volumes/omarchyuser/projekti/nodaysidle-project-pages",
            "/Volumes/omarchyuser/projekti/orbit-browser",
            "/Volumes/omarchyuser/projekti/synapse-notes",
            "/Volumes/omarchyuser/projekti/_github-migrations/nodaysidle-control-room"
        ],
        receiptRoots: [
            "/Volumes/omarchyuser/NODAYSIDLESCREENSHOTS",
            "/Volumes/omarchyuser/projekti/_github-migrations",
            "/Users/archuser/Documents/NODAYSIDLE"
        ])

    public static var defaultConfigURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nodaysidle-control-room/config.json")
    }

    public static func load(from url: URL = defaultConfigURL, fallback: ControlRoomConfig = .nodaysidleDefault) -> ControlRoomConfig {
        guard let data = try? Data(contentsOf: url) else { return fallback }
        do {
            return try JSONDecoder().decode(ControlRoomConfig.self, from: data)
        } catch {
            return fallback
        }
    }
}

public struct SystemScanner: Sendable {
    public let processScanner = ProcessScanner()
    public let repoScanner = RepoScanner()
    public let bridgeScanner = BridgeScanner()
    public let receiptScanner = ReceiptScanner()
    public let config: ControlRoomConfig
    public init(config: ControlRoomConfig = .load()) { self.config = config }
    public func snapshot() -> SystemSnapshot {
        SystemSnapshot(generatedAt: Date(), processes: processScanner.scan(), repos: repoScanner.scan(paths: config.repoPaths), bridges: bridgeScanner.scan(), receipts: receiptScanner.scan(roots: config.receiptRoots))
    }
}