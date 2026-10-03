import Foundation
import os

/// A rolling record of what the app did and how long it took, for debugging delivery between two Macs.
/// Every line also goes to the system log. The latest ~400 lines are uploaded to this identity's
/// `diag-<userId>` record every 15 s, so either partner can download both logs (♡ menu → Save Diagnostics).
/// Never records note text, photos, or keys — only events, counts, timings, and errors.
// ponytail: diagnostics records sit in the public database, readable by any install of the app.
// Fine for testing; turn `Config.Diagnostics.uploads` off (or move them to the private database) before real users.
@MainActor
final class Diagnostics {
    static let shared = Diagnostics()

    private var lines: [String] = []
    private var isDirty = false
    private var uploadTask: Task<Void, Never>?
    private let log = Logger(subsystem: "OurNotch", category: "diag")
    private let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZZZZ"
        return formatter
    }()

    var text: String { lines.joined(separator: "\n") }

    /// - Parameter who: which identity on this Mac ("me", or "sim" for the Partner Simulator).
    func record(_ message: String, who: String = "me") {
        let line = "\(clock.string(from: .now)) [\(who)] \(message)"
        log.notice("\(line, privacy: .public)")
        lines.append(line)
        if lines.count > Config.Diagnostics.maxLines { lines.removeFirst(lines.count - Config.Diagnostics.maxLines) }
        isDirty = true
    }

    /// Starts uploading this Mac's lines under the given identity. Safe to call more than once.
    func startUploading(owner: String, mailbox: Mailbox) {
        guard Config.Diagnostics.uploads, uploadTask == nil else { return }
        uploadTask = Task { [weak self] in
            while let self, !Task.isCancelled {
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

extension Error {
    /// "CKError 9 (…)" style detail, so logs show CloudKit's error code, not just the message.
    var diagnosticDescription: String {
        let ns = self as NSError
        return "\(ns.domain) \(ns.code): \(ns.localizedDescription)"
    }
}
