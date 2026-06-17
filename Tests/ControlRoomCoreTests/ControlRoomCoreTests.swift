import XCTest
@testable import ControlRoomCore

final class ControlRoomCoreTests: XCTestCase {
    func testProcessClassifierRecognizesCoreTools() {
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "/usr/local/bin/hermes gateway"), .hermes)
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "node /opt/codexpro start --port 8787"), .codexPro)
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "cloudflared tunnel --url http://127.0.0.1:8787"), .tunnel)
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "codex exec build"), .codex)
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "npm run dev -- --host 127.0.0.1"), .localServer)
    }
    func testProcessScannerParsesPsOutput() {
        let output = """
          101 /bin/zsh /bin/zsh -lc hermes gateway
          102 node node /usr/local/bin/codexpro start --port 8787
          103 bash bash boring command
        """
        let parsed = ProcessScanner().parse(psOutput: output)
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed.map(\.kind), [.codexPro, .hermes].sorted { $0.rawValue < $1.rawValue })
    }
    func testSnapshotOverallStatePrioritizesDirtyRepos() {
        let repo = RepoStatus(name: "x", path: "/tmp/x", branch: "main", dirtyCount: 1, remote: "none", lastCommit: "abc", state: .attention)
        let snapshot = SystemSnapshot(generatedAt: .now, processes: [], repos: [repo], bridges: [], receipts: [])
        XCTAssertEqual(snapshot.overallState, .attention)
    }
    func testBridgeKnownEndpointsIncludesHermesAndCodexPro() {
        let names = BridgeScanner().knownEndpoints().map(\.name)
        XCTAssertTrue(names.contains("Hermes Gateway"))
        XCTAssertTrue(names.contains("CodexPro MCP"))
    }

    func testReceiptScannerRootOnlyFiltersSortsAndLimits() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("control-room-receipts-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let old = root.appendingPathComponent("old-release.md")
        let recent = root.appendingPathComponent("new-receipt.txt")
        let ignored = root.appendingPathComponent("notes.md")
        try "old".write(to: old, atomically: true, encoding: .utf8)
        try "new".write(to: recent, atomically: true, encoding: .utf8)
        try "ignored".write(to: ignored, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 10)], ofItemAtPath: old.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 20)], ofItemAtPath: recent.path)

        let receipts = ReceiptScanner().scan(roots: [root.path], limit: 1)
        XCTAssertEqual(receipts.count, 1)
        XCTAssertEqual(receipts.first?.title, "new-receipt.txt")
    }
}
