import XCTest
@testable import ControlRoomCore

final class ControlRoomCoreTests: XCTestCase {
    // MARK: - ProcessClassifier
    func testProcessClassifierRecognizesCoreTools() {
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "/usr/local/bin/hermes gateway"), .hermes)
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "node /opt/codexpro start --port 8787"), .codexPro)
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "cloudflared tunnel --url http://127.0.0.1:8787"), .tunnel)
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "codex exec build"), .codex)
        XCTAssertEqual(ProcessClassifier.classify(commandLine: "npm run dev -- --host 127.0.0.1"), .localServer)
    }

    // MARK: - ProcessScanner
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

    // MARK: - SystemSnapshot
    func testSnapshotOverallStatePrioritizesDirtyRepos() {
        let repo = RepoStatus(name: "x", path: "/tmp/x", branch: "main", dirtyCount: 1, remote: "none", lastCommit: "abc", state: .attention)
        let snapshot = SystemSnapshot(generatedAt: .now, processes: [], repos: [repo], bridges: [], receipts: [])
        XCTAssertEqual(snapshot.overallState, .attention)
    }

    // MARK: - BridgeScanner
    func testBridgeKnownEndpointsIncludesHermesAndCodexPro() {
        let names = BridgeScanner().knownEndpoints().map(\.name)
        XCTAssertTrue(names.contains("Hermes Gateway"))
        XCTAssertTrue(names.contains("CodexPro MCP"))
    }

    func testBridgeScannerOpenAndClosed() {
        let scanner = BridgeScanner()
        XCTAssertFalse(scanner.isPortOpen(host: "127.0.0.1", port: 1, timeout: 0.1))
        let statuses = scanner.scan()
        for status in statuses {
            XCTAssertTrue(status.state == .live || status.state == .idle)
            XCTAssertTrue(status.endpoint.hasPrefix("http://"))
            XCTAssertFalse(status.name.isEmpty)
        }
    }

    // MARK: - ReceiptScanner
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

    // MARK: - Shell.run
    func testShellRunEchoReturnsSuccess() {
        let result = Shell.run("/bin/echo", ["hello", "world"])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("hello"))
    }

    func testShellRunTimeout() {
        let result = Shell.run("/bin/sleep", ["10"], timeout: 0.2)
        XCTAssertEqual(result.exitCode, 124)
    }

    func testShellRunLargeOutputDoesNotDeadlock() {
        let iterations = 50_000
        let cmd = "yes line | head -n \(iterations)"
        let result = Shell.run("/bin/bash", ["-c", cmd], timeout: 15)
        XCTAssertEqual(result.exitCode, 0)
        let lineCount = result.output.split(separator: "\n", omittingEmptySubsequences: false).filter { $0 == "line" }.count
        XCTAssertEqual(lineCount, iterations)
    }

    func testShellRunInvalidExecutable() {
        let result = Shell.run("/nonexistent/command", [])
        XCTAssertNotEqual(result.exitCode, 0)
    }

    // MARK: - RepoScanner with temp git repo
    func testRepoScannerOnTempGitRepoClean() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("repo-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        XCTAssertEqual(Shell.run("/usr/bin/git", ["init", "-b", "main"], currentDirectory: tmp.path).exitCode, 0)
        _ = Shell.run("/usr/bin/git", ["-C", tmp.path, "config", "user.email", "test@test.com"])
        _ = Shell.run("/usr/bin/git", ["-C", tmp.path, "config", "user.name", "Tester"])
        try "initial".write(to: tmp.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        _ = Shell.run("/usr/bin/git", ["-C", tmp.path, "add", "."])
        XCTAssertEqual(Shell.run("/usr/bin/git", ["-C", tmp.path, "commit", "-m", "init"]).exitCode, 0)

        let status = RepoScanner().scan(path: tmp.path)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.dirtyCount, 0)
        XCTAssertEqual(status?.state, .live)
        XCTAssertEqual(status?.branch, "main")
    }

    func testRepoScannerOnTempGitRepoDirty() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("repo-dirty-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        XCTAssertEqual(Shell.run("/usr/bin/git", ["init", "-b", "main"], currentDirectory: tmp.path).exitCode, 0)
        _ = Shell.run("/usr/bin/git", ["-C", tmp.path, "config", "user.email", "test@test.com"])
        _ = Shell.run("/usr/bin/git", ["-C", tmp.path, "config", "user.name", "Tester"])
        try "initial".write(to: tmp.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        _ = Shell.run("/usr/bin/git", ["-C", tmp.path, "add", "."])
        XCTAssertEqual(Shell.run("/usr/bin/git", ["-C", tmp.path, "commit", "-m", "init"]).exitCode, 0)
        try "modified".write(to: tmp.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

        let status = RepoScanner().scan(path: tmp.path)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.dirtyCount, 1)
        XCTAssertEqual(status?.state, .attention)
    }

    func testRepoScannerOnNonGitDirectoryReturnsNil() {
        let status = RepoScanner().scan(path: NSTemporaryDirectory())
        XCTAssertNil(status)
    }

    // MARK: - SystemScanner custom config
    func testSystemScannerWithCustomConfig() {
        let custom = ControlRoomConfig(repoPaths: ["/tmp/fake-repo"], receiptRoots: ["/tmp/fake-receipts"])
        let scanner = SystemScanner(config: custom)
        XCTAssertEqual(scanner.config.repoPaths, ["/tmp/fake-repo"])
        XCTAssertEqual(scanner.config.receiptRoots, ["/tmp/fake-receipts"])
        let snapshot = scanner.snapshot()
        XCTAssertEqual(snapshot.repos.count, 0)
    }

    func testControlRoomConfigLoadFallsBackToDefault() {
        let missing = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("missing-\(UUID().uuidString).json")
        let config = ControlRoomConfig.load(from: missing)
        XCTAssertEqual(config, ControlRoomConfig.nodaysidleDefault)
    }

    func testControlRoomConfigLoadsJSONFile() throws {
        let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("control-room-config-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        try #"{"repoPaths":["/tmp/repo-a"],"receiptRoots":["/tmp/receipts-a"]}"#.write(to: file, atomically: true, encoding: .utf8)
        let config = ControlRoomConfig.load(from: file)
        XCTAssertEqual(config.repoPaths, ["/tmp/repo-a"])
        XCTAssertEqual(config.receiptRoots, ["/tmp/receipts-a"])
    }
}
