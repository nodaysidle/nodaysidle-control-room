import Foundation

public struct RepoScanner: Sendable {
    public init() {}
    public func scan(paths: [String]) -> [RepoStatus] { paths.compactMap { scan(path: $0) } }
    public func scan(path: String) -> RepoStatus? {
        guard FileManager.default.fileExists(atPath: path + "/.git") else { return nil }
        let name = URL(fileURLWithPath: path).lastPathComponent
        let branch = git(["rev-parse", "--abbrev-ref", "HEAD"], path: path).cleaned(default: "UNKNOWN")
        let status = git(["status", "--short"], path: path).output
        let dirty = status.split(separator: "\n").count
        let remote = git(["remote", "get-url", "origin"], path: path).cleaned(default: "no-origin")
        let last = git(["log", "-1", "--pretty=%h %s"], path: path).cleaned(default: "no-commits")
        return RepoStatus(name: name, path: path, branch: branch, dirtyCount: dirty, remote: remote, lastCommit: last, state: dirty > 0 ? .attention : .live)
    }
    private func git(_ args: [String], path: String) -> ShellResult { Shell.run("/usr/bin/git", args, currentDirectory: path, timeout: 4) }
}

private extension ShellResult {
    func cleaned(default fallback: String) -> String {
        guard exitCode == 0 else { return fallback }
        let value = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? fallback : value
    }
}
