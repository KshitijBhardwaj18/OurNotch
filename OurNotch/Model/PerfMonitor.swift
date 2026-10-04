import AppKit

/// Measures lag for the diagnostics log, tagged `[perf]` so a test session can be reviewed afterwards:
/// - `track` watches one animation (notch open, pour, splash, banner…) frame by frame and logs
///   how many frames it dropped and its worst frame.
/// - A watchdog thread logs any moment the main thread stops responding for 250 ms or more (a hang),
///   with what was animating and the last thing the app did.
@MainActor
final class PerfMonitor: NSObject {
    static let shared = PerfMonitor()

    private struct Span {
        let name: String
        let started: CFTimeInterval
        let ends: CFTimeInterval
        var frames = 0
        var dropped = 0
        var worst: CFTimeInterval = 0
    }

    private var spans: [UUID: Span] = [:]
    private var link: CADisplayLink?
    private var lastFrame: CFTimeInterval?
    private var lastEvent = ""

    /// Names of what's animating right now, for hang reports.
    var activity: String {
        spans.isEmpty ? "idle" : spans.values.map(\.name).sorted().joined(separator: " + ")
    }

    /// Remembers the latest diagnostics line, so a hang says what the app had just done.
    func noteEvent(_ line: String) { lastEvent = line }

    /// Watches the next `seconds` of frames and logs one `[perf]` line for them.
    func track(_ name: String, seconds: Double) {
        let now = CACurrentMediaTime()
        spans[UUID()] = Span(name: name, started: now, ends: now + seconds)
        guard link == nil, let screen = NSScreen.main else { return }
        let link = screen.displayLink(target: self, selector: #selector(frame))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    @objc private func frame(_ link: CADisplayLink) {
        let expected = max(link.targetTimestamp - link.timestamp, 1.0 / 240)
        if let last = lastFrame {
            let interval = link.timestamp - last
            let missed = max(0, Int((interval / expected).rounded()) - 1)
            for id in spans.keys {
                spans[id]!.frames += 1
                spans[id]!.dropped += missed
                spans[id]!.worst = max(spans[id]!.worst, interval)
            }
        }
        lastFrame = link.timestamp

        for (id, span) in spans where link.timestamp >= span.ends {
            spans[id] = nil
            let total = span.frames + span.dropped
            let percent = total == 0 ? 0 : span.dropped * 100 / total
            let verdict = percent >= 10 || span.worst > 0.1 ? "LAGGED" : "smooth"
            Diagnostics.shared.record(String(
                format: "[perf] %@ %@: %d frames at %.0f Hz, %d dropped (%d%%), worst frame %.0f ms",
                span.name, verdict, span.frames, 1 / expected, span.dropped, percent, span.worst * 1000),
                metric: Metric(kind: .frames, name: span.name, ms: span.worst * 1000,
                               frames: span.frames, dropped: span.dropped, detail: String(format: "%.0f Hz", 1 / expected)))
        }
        if spans.isEmpty {
            link.invalidate()
            self.link = nil
            lastFrame = nil
        }
    }

    /// Starts the hang watchdog. Call once at launch.
    nonisolated func startWatchdog() {
        let thread = Thread {
            while true {
                let sent = CACurrentMediaTime()
                let answered = DispatchSemaphore(value: 0)
                DispatchQueue.main.async { answered.signal() }
                if answered.wait(timeout: .now() + 0.25) == .timedOut {
                    answered.wait()
                    let blocked = CACurrentMediaTime() - sent
                    // ponytail: a sleeping or App-Napped Mac also stalls the main queue; anything over 30 s is
                    // treated as that, not a hang. Use MetricKit's hang reports if this proves noisy.
                    if blocked < 30 {
                        DispatchQueue.main.async {
                            let monitor = PerfMonitor.shared
                            Diagnostics.shared.record(String(
                                format: "[perf] HANG main thread blocked %.0f ms · animating: %@ · last event: %@",
                                blocked * 1000, monitor.activity, monitor.lastEvent),
                                metric: Metric(kind: .hang, name: monitor.activity, ms: blocked * 1000, detail: monitor.lastEvent))
                        }
                    }
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        thread.name = "OurNotch hang watchdog"
        thread.qualityOfService = .userInteractive
        thread.start()
    }
}
