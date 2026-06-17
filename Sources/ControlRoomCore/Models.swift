import Foundation

public enum SignalState: String, Codable, CaseIterable, Sendable {
    case live = "Live"
    case attention = "Needs Attention"
    case idle = "Idle"
    case unknown = "Unknown"
}

public enum ProcessKind: String, Codable, CaseIterable, Sendable {
    case hermes = "Hermes"
    case codex = "Codex"
    case codexPro = "CodexPro"
    case tunnel = "Tunnel"
    case localServer = "Local Server"
    case vercel = "Vercel"
    case other = "Other"
}

public struct AgentProcess: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let pid: Int
    public let kind: ProcessKind
    public let command: String
    public let detail: String
    public let state: SignalState
    public init(pid: Int, kind: ProcessKind, command: String, detail: String, state: SignalState = .live) {
        self.id = "\(pid)-\(kind.rawValue)-\(command)"
        self.pid = pid; self.kind = kind; self.command = command; self.detail = detail; self.state = state
    }
}

public struct RepoStatus: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let branch: String
    public let dirtyCount: Int
    public let remote: String
    public let lastCommit: String
    public let state: SignalState
    public init(name: String, path: String, branch: String, dirtyCount: Int, remote: String, lastCommit: String, state: SignalState) {
        self.id = path; self.name = name; self.path = path; self.branch = branch; self.dirtyCount = dirtyCount; self.remote = remote; self.lastCommit = lastCommit; self.state = state
    }
}

public struct BridgeStatus: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let endpoint: String
    public let state: SignalState
    public let detail: String
    public init(name: String, endpoint: String, state: SignalState, detail: String) {
        self.id = "\(name)-\(endpoint)"; self.name = name; self.endpoint = endpoint; self.state = state; self.detail = detail
    }
}

public struct Receipt: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let path: String
    public let timestamp: Date
    public init(title: String, path: String, timestamp: Date) { self.id = path; self.title = title; self.path = path; self.timestamp = timestamp }
}

public struct SystemSnapshot: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let processes: [AgentProcess]
    public let repos: [RepoStatus]
    public let bridges: [BridgeStatus]
    public let receipts: [Receipt]
    public init(generatedAt: Date, processes: [AgentProcess], repos: [RepoStatus], bridges: [BridgeStatus], receipts: [Receipt]) {
        self.generatedAt = generatedAt; self.processes = processes; self.repos = repos; self.bridges = bridges; self.receipts = receipts
    }
    public var overallState: SignalState {
        if repos.contains(where: { $0.state == .attention }) { return .attention }
        if !processes.isEmpty || bridges.contains(where: { $0.state == .live }) { return .live }
        return .idle
    }
}
