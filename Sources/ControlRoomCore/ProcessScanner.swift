import Foundation

public enum ProcessClassifier {
    public static func classify(commandLine: String) -> ProcessKind? {
        let lower = commandLine.lowercased()
        if lower.contains("codexpro") { return .codexPro }
        if lower.contains("hermes") { return .hermes }
        if lower.contains("cloudflared") || lower.contains("tunnel-client") || lower.contains("trycloudflare") { return .tunnel }
        if lower.contains(" vercel") || lower.contains("/vercel") { return .vercel }
        if lower.contains("codex") { return .codex }
        if lower.contains("vite") || lower.contains("next dev") || lower.contains("npm run dev") || lower.contains("node") { return .localServer }
        return nil
    }
    public static func detail(for commandLine: String) -> String {
        let trimmed = commandLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count <= 96 ? trimmed : String(trimmed.prefix(96)) + "…"
    }
}

public struct ProcessScanner: Sendable {
    public init() {}
    public func scan() -> [AgentProcess] {
        let result = Shell.run("/bin/ps", ["-axo", "pid=,comm=,args="])
        guard result.exitCode == 0 else { return [] }
        return parse(psOutput: result.output)
    }
    public func parse(psOutput: String) -> [AgentProcess] {
        psOutput.split(separator: "\n").compactMap { line in
            let text = String(line).trimmingCharacters(in: .whitespaces)
            guard let firstSpace = text.firstIndex(where: { $0 == " " || $0 == "\t" }) else { return nil }
            let pidText = String(text[..<firstSpace]).trimmingCharacters(in: .whitespaces)
            guard let pid = Int(pidText), pid != ProcessInfo.processInfo.processIdentifier else { return nil }
            let rest = String(text[firstSpace...]).trimmingCharacters(in: .whitespaces)
            guard let kind = ProcessClassifier.classify(commandLine: rest) else { return nil }
            let command = rest.split(separator: " ").first.map(String.init) ?? rest
            return AgentProcess(pid: pid, kind: kind, command: URL(fileURLWithPath: command).lastPathComponent, detail: ProcessClassifier.detail(for: rest))
        }.sorted { $0.kind.rawValue == $1.kind.rawValue ? $0.pid < $1.pid : $0.kind.rawValue < $1.kind.rawValue }
    }
}
