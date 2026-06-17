import Foundation

public struct ShellResult: Sendable, Equatable { public let output: String; public let exitCode: Int32 }

public enum Shell {
    public static func run(_ executable: String, _ arguments: [String], currentDirectory: String? = nil, timeout: TimeInterval = 5) -> ShellResult {
        let process = Process(); process.executableURL = URL(fileURLWithPath: executable); process.arguments = arguments
        if let currentDirectory { process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory) }
        let pipe = Pipe(); process.standardOutput = pipe; process.standardError = pipe
        do { try process.run() } catch { return ShellResult(output: String(describing: error), exitCode: 127) }
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
        if process.isRunning { process.terminate(); return ShellResult(output: "timeout", exitCode: 124) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return ShellResult(output: String(data: data, encoding: .utf8) ?? "", exitCode: process.terminationStatus)
    }
}
