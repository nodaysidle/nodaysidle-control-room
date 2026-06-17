import Foundation

public struct BridgeScanner: Sendable {
    public init() {}
    public func scan() -> [BridgeStatus] {
        knownEndpoints().map { endpoint in
            let open = isPortOpen(host: endpoint.host, port: endpoint.port, timeout: 0.18)
            return BridgeStatus(name: endpoint.name, endpoint: "http://\(endpoint.host):\(endpoint.port)", state: open ? .live : .idle, detail: open ? "TCP port responds" : "No listener detected")
        }
    }
    public func knownEndpoints() -> [(name: String, host: String, port: Int)] {
        [("Hermes Gateway", "127.0.0.1", 8642), ("CodexPro MCP", "127.0.0.1", 8787), ("Vite Preview", "127.0.0.1", 4173), ("Vercel Dev", "127.0.0.1", 3000)]
    }
    public func isPortOpen(host: String, port: Int, timeout: TimeInterval) -> Bool {
        var input: InputStream?; var output: OutputStream?
        Stream.getStreamsToHost(withName: host, port: port, inputStream: &input, outputStream: &output)
        guard let output else { return false }
        output.open(); defer { output.close() }
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if output.streamStatus == .open { return true }
            if output.streamStatus == .error || output.streamStatus == .closed { return false }
            Thread.sleep(forTimeInterval: 0.02)
        }
        return false
    }
}
