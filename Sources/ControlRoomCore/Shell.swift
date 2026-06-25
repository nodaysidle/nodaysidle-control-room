import Foundation

public struct ShellResult: Sendable, Equatable { public let output: String; public let exitCode: Int32 }

public enum Shell {
    public static func run(_ executable: String, _ arguments: [String], currentDirectory: String? = nil, timeout: TimeInterval = 5) -> ShellResult {
        let process = Process(); process.executableURL = URL(fileURLWithPath: executable); process.arguments = arguments
        if let currentDirectory { process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory) }
        let pipe = Pipe(); process.standardOutput = pipe; process.standardError = pipe
        let output = LockedOutputBuffer(maxBytes: 4 * 1024 * 1024)
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if !chunk.isEmpty { output.append(chunk) }
        }
        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in finished.signal() }
        do { try process.run() } catch { return ShellResult(output: String(describing: error), exitCode: 127) }
        if finished.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            _ = finished.wait(timeout: .now() + 1)
            pipe.fileHandleForReading.readabilityHandler = nil
            output.append(pipe.fileHandleForReading.readDataToEndOfFile())
            return ShellResult(output: output.string(fallback: "timeout"), exitCode: 124)
        }
        pipe.fileHandleForReading.readabilityHandler = nil
        output.append(pipe.fileHandleForReading.readDataToEndOfFile())
        return ShellResult(output: output.string(), exitCode: process.terminationStatus)
    }
}

private final class LockedOutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    private let maxBytes: Int

    init(maxBytes: Int) { self.maxBytes = maxBytes }

    func append(_ chunk: Data) {
        lock.lock(); defer { lock.unlock() }
        guard data.count < maxBytes else { return }
        data.append(chunk.prefix(maxBytes - data.count))
    }

    func string(fallback: String = "") -> String {
        lock.lock(); defer { lock.unlock() }
        let value = String(data: data, encoding: .utf8) ?? ""
        return value.isEmpty ? fallback : value
    }
}