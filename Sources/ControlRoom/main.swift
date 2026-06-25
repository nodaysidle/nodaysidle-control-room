import SwiftUI
import AppKit
import ControlRoomCore

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var snapshot = SystemSnapshot(generatedAt: .now, processes: [], repos: [], bridges: [], receipts: [])
    @Published var isRefreshing = false
    private let scanner = SystemScanner()
    func refresh() { isRefreshing = true; Task.detached(priority: .userInitiated) { [scanner] in let snap = scanner.snapshot(); await MainActor.run { self.snapshot = snap; self.isRefreshing = false } } }
    func openPath(_ path: String) { NSWorkspace.shared.open(URL(fileURLWithPath: path)) }
    func copy(_ text: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string) }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = DashboardViewModel()
    var window: NSWindow?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        createStatusItem()
        showWindow()
        model.refresh()
        if ProcessInfo.processInfo.environment["CONTROL_ROOM_SCREENSHOT_PATH"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.writeSelfScreenshotIfRequested()
            }
        }
    }

    func writeSelfScreenshotIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["CONTROL_ROOM_SCREENSHOT_PATH"], let view = window?.contentView else { return }
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) ?? NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(view.bounds.width), pixelsHigh: Int(view.bounds.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        guard let rep else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
        if ProcessInfo.processInfo.environment["CONTROL_ROOM_SCREENSHOT_EXIT"] == "1" {
            NSApp.terminate(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func showWindow() {
        if window == nil {
            let root = ControlRoomWindow(model: model)
                .frame(width: 1280, height: 820)
            let hosting = NSHostingView(rootView: root)
            let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            win.title = "NODAYSIDLE Control Room"
            win.contentView = hosting
            win.isReleasedWhenClosed = false
            win.minSize = NSSize(width: 1120, height: 720)
            win.center()
            window = win
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: "NODAYSIDLE Control Room")
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Control Room", action: #selector(openFromMenu), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh Scan", action: #selector(refreshFromMenu), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitFromMenu), keyEquivalent: "q"))
        for item in menu.items { item.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc func openFromMenu() { showWindow() }
    @objc func refreshFromMenu() { model.refresh() }
    @objc func quitFromMenu() { NSApp.terminate(nil) }
}

struct ControlRoomWindow: View {
    @ObservedObject var model: DashboardViewModel
    var body: some View { ZStack { PremiumBackground(); ScrollView { VStack(alignment: .leading, spacing: 18) { Header(model: model); MissionStrip(snapshot: model.snapshot); HStack(alignment: .top, spacing: 16) { AgentColumn(model: model); RepoColumn(model: model) }; HStack(alignment: .top, spacing: 16) { BridgeColumn(model: model); ReceiptColumn(model: model) } }.padding(24).frame(maxWidth: .infinity, alignment: .topLeading) } }.foregroundStyle(.white) }
}

struct Header: View {
    @ObservedObject var model: DashboardViewModel
    var body: some View { HStack { HStack(spacing: 14) { LogoMark().frame(width: 54, height: 54); VStack(alignment: .leading, spacing: 4) { Text("NODAYSIDLE CONTROL ROOM").font(.system(size: 13, weight: .semibold, design: .monospaced)).tracking(2.1).foregroundStyle(Color.volt); Text("Local agent operations. Real state. No theater.").font(.system(size: 30, weight: .black)); Text("Last scan \(model.snapshot.generatedAt.formatted(date: .omitted, time: .standard))").font(.caption).foregroundStyle(.white.opacity(0.54)) } }; Spacer(); Button(action: { model.refresh() }) { Label(model.isRefreshing ? "Scanning" : "Refresh", systemImage: "arrow.clockwise").font(.system(size: 13, weight: .bold)).padding(.horizontal, 16).padding(.vertical, 10).background(Color.volt).foregroundStyle(.black).clipShape(Capsule()) }.buttonStyle(.plain).accessibilityLabel("Refresh local status scan") } }
}

struct MissionStrip: View { let snapshot: SystemSnapshot; var body: some View { HStack(spacing: 12) { StatPill(title: "Mission", value: snapshot.overallState.rawValue, state: snapshot.overallState); StatPill(title: "Agents", value: "\(snapshot.processes.count)", state: snapshot.processes.isEmpty ? .idle : .live); StatPill(title: "Dirty repos", value: "\(snapshot.repos.filter { $0.dirtyCount > 0 }.count)", state: snapshot.repos.contains { $0.dirtyCount > 0 } ? .attention : .live); StatPill(title: "Live bridges", value: "\(snapshot.bridges.filter { $0.state == .live }.count)", state: snapshot.bridges.contains { $0.state == .live } ? .live : .idle); StatPill(title: "Receipts", value: "\(snapshot.receipts.count)", state: snapshot.receipts.isEmpty ? .unknown : .live) } } }
struct AgentColumn: View { @ObservedObject var model: DashboardViewModel; var body: some View { Panel(title: "Agent sessions", subtitle: "Hermes, Codex, tunnels, local servers") { if model.snapshot.processes.isEmpty { EmptyPanel(icon: "moon.zzz", title: "No agent processes observed", detail: "The scanner found no matching Hermes/Codex/tunnel/dev-server processes.") } else { ForEach(model.snapshot.processes.prefix(8)) { process in RowCard(state: process.state, title: process.kind.rawValue, meta: "PID \(process.pid) • \(process.command)", detail: process.detail) { Button("Copy") { model.copy(process.detail) }.buttonStyle(.borderless) } } } } } }
struct RepoColumn: View { @ObservedObject var model: DashboardViewModel; var body: some View { Panel(title: "Project watchlist", subtitle: "Branch, dirt, remote, last commit") { if model.snapshot.repos.isEmpty { EmptyPanel(icon: "folder.badge.questionmark", title: "No watched repos found", detail: "Configured repo paths are missing or not git repositories.") } else { ForEach(model.snapshot.repos) { repo in RowCard(state: repo.state, title: repo.name, meta: "\(repo.branch) • dirty \(repo.dirtyCount)", detail: repo.lastCommit) { Button("Open") { model.openPath(repo.path) }.buttonStyle(.borderless); Button("Copy remote") { model.copy(repo.remote) }.buttonStyle(.borderless) } } } } } }
struct BridgeColumn: View { @ObservedObject var model: DashboardViewModel; var body: some View { Panel(title: "Local bridges", subtitle: "Known loopback endpoints") { ForEach(model.snapshot.bridges) { bridge in RowCard(state: bridge.state, title: bridge.name, meta: bridge.endpoint, detail: bridge.detail) { Button("Copy") { model.copy(bridge.endpoint) }.buttonStyle(.borderless) } } } } }
struct ReceiptColumn: View { @ObservedObject var model: DashboardViewModel; var body: some View { Panel(title: "Recent receipts", subtitle: "Local proof files discovered") { if model.snapshot.receipts.isEmpty { EmptyPanel(icon: "doc.text.magnifyingglass", title: "No receipt files found", detail: "No matching receipt/handoff/release files were detected in configured roots.") } else { ForEach(model.snapshot.receipts.prefix(6)) { receipt in RowCard(state: .live, title: receipt.title, meta: receipt.timestamp.formatted(date: .abbreviated, time: .shortened), detail: receipt.path) { Button("Open") { model.openPath(receipt.path) }.buttonStyle(.borderless) } } } } } }

struct Panel<Content: View>: View { let title: String; let subtitle: String; @ViewBuilder let content: Content; var body: some View { VStack(alignment: .leading, spacing: 12) { VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 18, weight: .heavy)); Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.52)) }; VStack(spacing: 10) { content } }.padding(16).frame(maxWidth: .infinity, alignment: .topLeading).background(.black.opacity(0.34)).overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.08), lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 24)) } }
struct RowCard<Actions: View>: View { let state: SignalState; let title: String; let meta: String; let detail: String; @ViewBuilder let actions: Actions; var body: some View { HStack(alignment: .center, spacing: 12) { Circle().fill(state.color).frame(width: 9, height: 9).shadow(color: state.color.opacity(0.55), radius: 7); VStack(alignment: .leading, spacing: 4) { HStack { Text(title).font(.system(size: 14, weight: .bold)); Spacer(); Text(state.rawValue).font(.caption2).foregroundStyle(state.color) }; Text(meta).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(.white.opacity(0.58)).lineLimit(1); Text(detail).font(.caption).foregroundStyle(.white.opacity(0.45)).lineLimit(1) }; HStack(spacing: 8) { actions }.font(.caption) }.padding(12).background(Color.white.opacity(0.045)).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 16)) } }
struct StatPill: View { let title: String; let value: String; let state: SignalState; var body: some View { VStack(alignment: .leading, spacing: 3) { Text(title.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.4).foregroundStyle(.white.opacity(0.45)); Text(value).font(.system(size: 17, weight: .heavy)).foregroundStyle(state.color) }.padding(.horizontal, 16).padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading).background(.white.opacity(0.055)).clipShape(RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(state.color.opacity(0.22), lineWidth: 1)) } }
struct EmptyPanel: View { let icon: String; let title: String; let detail: String; var body: some View { VStack(alignment: .leading, spacing: 10) { Image(systemName: icon).font(.title2).foregroundStyle(Color.volt.opacity(0.7)); Text(title).font(.headline); Text(detail).font(.caption).foregroundStyle(.white.opacity(0.5)) }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white.opacity(0.035)).clipShape(RoundedRectangle(cornerRadius: 18)) } }
struct PremiumBackground: View { var body: some View { ZStack { LinearGradient(colors: [Color(red: 0.025, green: 0.027, blue: 0.025), Color(red: 0.055, green: 0.064, blue: 0.055), .black], startPoint: .topLeading, endPoint: .bottomTrailing); RadialGradient(colors: [Color.volt.opacity(0.20), .clear], center: .topTrailing, startRadius: 60, endRadius: 620); GeometryReader { geo in Path { path in let step: CGFloat = 44; for x in stride(from: CGFloat(0), through: geo.size.width, by: step) { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: geo.size.height)) }; for y in stride(from: CGFloat(0), through: geo.size.height, by: step) { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: geo.size.width, y: y)) } }.stroke(.white.opacity(0.025), lineWidth: 1) } }.ignoresSafeArea() } }
struct LogoMark: View { var body: some View { ZStack { RoundedRectangle(cornerRadius: 16).fill(.black.opacity(0.8)); RoundedRectangle(cornerRadius: 16).stroke(Color.volt, lineWidth: 1.6); Text("NDI").font(.system(size: 16, weight: .black, design: .monospaced)).foregroundStyle(Color.volt); Circle().stroke(Color.volt.opacity(0.34), lineWidth: 1).frame(width: 38, height: 38) } } }
extension Color { static let volt = Color(red: 0.784, green: 1.0, blue: 0.0) }
extension SignalState { var color: Color { switch self { case .live: return .volt; case .attention: return Color(red: 1.0, green: 0.62, blue: 0.18); case .idle: return Color(red: 0.55, green: 0.62, blue: 0.66); case .unknown: return Color(red: 0.45, green: 0.74, blue: 1.0) } }; var symbol: String { switch self { case .live: return "bolt.circle.fill"; case .attention: return "exclamationmark.triangle.fill"; case .idle: return "moon.circle"; case .unknown: return "questionmark.circle" } } }

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
