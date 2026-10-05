import Foundation
import os

/// A rolling record of what the app did and how long it took, for debugging delivery between two Macs.
/// Every line also goes to the system log and is appended to `~/Library/Logs/OurNotch/this-mac.log`
/// (kept across launches, so a whole test session can be reviewed). The latest lines are uploaded to this identity's
/// `diag-<userId>` record every 15 s, so either partner can download both logs (♡ menu → Save Diagnostics).
/// Measurements (frames, hangs, delivery times, request times) are also saved as one CloudKit `Metric`
/// record each, from both Macs, so a test session can be queried and compared side by side.
/// Never records note text, photos, or keys: only events, counts, timings, and errors.
// ponytail: diagnostics records sit in the public database, readable by any install of the app.
// Only Debug and Beta builds upload (`Config.Diagnostics.uploads`); the sold Release build never does.
@MainActor
final class Diagnostics {
    static let shared = Diagnostics()

    private var lines: [String] = []
    /// Measurements not uploaded yet.
    private(set) var pendingMetrics: [Metric] = []
    /// The identity measurements are saved under when they don't name one; set by `startUploading`.
    private var owner = ""
    private var isDirty = false
    private var uploadTask: Task<Void, Never>?
    private let log = Logger(subsystem: "OurNotch", category: "diag")
    private let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZZZZ"
        return formatter
    }()

    var text: String { lines.joined(separator: "\n") }

    static let folder = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Logs/OurNotch")
    /// Nil inside unit tests, so test runs don't fill the real log.
    private let file: FileHandle? = {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return nil }
        let url = Diagnostics.folder.appending(path: "this-mac.log")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        // Past the size limit, start fresh and keep one previous file.
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        if size > Config.Diagnostics.maxFileBytes {
            let old = folder.appending(path: "this-mac.previous.log")
            try? FileManager.default.removeItem(at: old)
            try? FileManager.default.moveItem(at: url, to: old)
        }
        if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
        let handle = try? FileHandle(forWritingTo: url)
        _ = try? handle?.seekToEnd()
        return handle
    }()

    /// - Parameters:
    ///   - who: which identity on this Mac ("me", or "sim" for the Partner Simulator).
    ///   - metric: the same event as numbers, saved to CloudKit for analysis.
    func record(_ message: String, who: String = "me", metric: Metric? = nil) {
        if let metric { measure(metric) }
        let line = "\(clock.string(from: .now)) [\(who)] \(message)"
        log.notice("\(line, privacy: .public)")
        lines.append(line)
        try? file?.write(contentsOf: Data((line + "\n").utf8))
        if !message.hasPrefix("[perf]") { PerfMonitor.shared.noteEvent(line) }
        if lines.count > Config.Diagnostics.maxLines { lines.removeFirst(lines.count - Config.Diagnostics.maxLines) }
        isDirty = true
    }

    /// Queues a measurement for CloudKit without a log line.
    func measure(_ metric: Metric) {
        var metric = metric
        if metric.owner.isEmpty { metric.owner = owner }
        pendingMetrics.append(metric)
        // ponytail: offline for hours could grow this; drop the oldest past 5,000.
        if pendingMetrics.count > 5000 { pendingMetrics.removeFirst(pendingMetrics.count - 5000) }
    }

    /// Starts uploading this Mac's lines under the given identity. Safe to call more than once.
    func startUploading(owner: String, mailbox: Mailbox) {
        guard Config.Diagnostics.uploads, uploadTask == nil else { return }
        self.owner = owner
        for i in pendingMetrics.indices where pendingMetrics[i].owner.isEmpty { pendingMetrics[i].owner = owner }
        uploadTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                if !self.pendingMetrics.isEmpty {
                    let batch = Array(self.pendingMetrics.prefix(400)) // CloudKit's limit per request
                    do {
                        try await mailbox.saveMetrics(batch)
                        self.pendingMetrics.removeFirst(batch.count)
                    } catch {
                        self.log.error("Metrics upload failed: \(error.localizedDescription, privacy: .public)")
                    }
                }
                if self.isDirty {
                    self.isDirty = false
                    do {
                        try await mailbox.saveDiagnostics(self.text, owner: owner)
                    } catch {
                        self.isDirty = true
                        self.log.error("Diagnostics upload failed: \(error.localizedDescription, privacy: .public)")
                    }
                }
                try? await Task.sleep(for: Config.Diagnostics.uploadInterval)
            }
        }
    }
}

/// One measurement. Both Macs save these to CloudKit (`Metric` records); ♡ → Save Diagnostics exports
/// both sides to `metrics.csv`.
struct Metric: Codable, Sendable, Equatable {
    enum Kind: String, Codable, Sendable {
        /// An animation: `ms` is its worst frame; `frames` and `dropped` count them.
        case frames
        /// The main thread stopped responding: `ms` is how long; `name` is what was animating.
        case hang
        /// Something from the partner appeared here: `ms` from their tap to shown; `detail` is what triggered the check.
        case arrival
        /// The partner's Mac showed what I sent: `ms` from my tap to their "seen" reaching me.
        case delivered
        /// A CloudKit request: `ms` is how long it took; `detail` says why it ran, or that it failed.
        case cloud
        /// A CloudKit ping arrived.
        case ping
    }

    var at = Date.now
    /// The identity that measured it. Filled in by `Diagnostics` when left empty.
    var owner = ""
    let kind: Kind
    let name: String
    var ms: Double = 0
    var frames: Int?
    var dropped: Int?
    var detail: String?
    var device = Metric.device

    static func ms(since date: Date) -> Double { Date.now.timeIntervalSince(date) * 1000 }

    /// "Mac16,12 · macOS 26.6.2 · 0.1 (1) Release"
    static let device: String = {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let info = Bundle.main.infoDictionary
        let os = ProcessInfo.processInfo.operatingSystemVersion
        #if DEBUG
        let build = "Debug"
        #else
        let build = "Release"
        #endif
        return "\(String(cString: model)) · macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion) · \(info?["CFBundleShortVersionString"] ?? "?") (\(info?["CFBundleVersion"] ?? "?")) \(build)"
    }()
}

extension Error {
    /// "CKError 9 (…)" style detail, so logs show CloudKit's error code, not just the message.
    var diagnosticDescription: String {
        let ns = self as NSError
        return "\(ns.domain) \(ns.code): \(ns.localizedDescription)"
    }
}
