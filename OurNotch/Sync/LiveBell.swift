import CryptoKit
import Foundation

/// The doorbell: a socket to our couple's room on Cloudflare (`live/`). After saving, a Mac rings, and the
/// other Mac checks iCloud straight away instead of waiting for Apple's ping or its next timed check.
/// Only the word "ring" travels; everything else stays in iCloud, encrypted. If Cloudflare is off or
/// unreachable, pings and timed checks carry on exactly as without it.
@MainActor
final class LiveBell {
    /// My love's Mac rang (it just saved), or the room changed (one of us joined after a gap): check now.
    var onCheck: (() -> Void)?
    /// What happened, for the diagnostics log.
    var onNote: ((String) -> Void)?
    /// Both Macs are in the room, so a ring from either is heard.
    private(set) var partnerHere = false

    private let url: URL
    private var socket: URLSessionWebSocketTask?
    private var task: Task<Void, Never>?
    private var lastPong = Date.distantPast

    init(key: SymmetricKey, role: Pairing.Role, url: URL = Config.Live.url) {
        // The room is named by a hash of our shared key: only our two Macs can work it out, and it says nothing about us.
        let room = HMAC<SHA256>.authenticationCode(for: Data("OurNotch live room".utf8), using: key)
            .map { String(format: "%02x", $0) }.joined()
        self.url = url.appending(path: "v1/room/\(room)")
            .appending(queryItems: [URLQueryItem(name: "me", value: role.rawValue)])
    }

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            var retry = Config.Live.firstRetry
            while !Task.isCancelled, let self {
                let connected = await self.connect()
                retry = connected ? Config.Live.firstRetry : min(retry * 2, Config.Live.lastRetry)
                try? await Task.sleep(for: .seconds(retry))
            }
        }
    }

    /// After sleep the old socket is usually dead; drop it so the next one opens in a couple of seconds.
    func reconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
    }

    func ring() {
        guard let socket, partnerHere else { return }
        socket.send(.string("ring")) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in self?.onNote?("ring FAILED: \(error.diagnosticDescription)") }
        }
    }

    /// Holds one socket until it drops. Returns whether it got as far as the room.
    private func connect() async -> Bool {
        let socket = URLSession.shared.webSocketTask(with: url)
        self.socket = socket
        socket.resume()
        let keepAlive = Task { [weak self] in await self?.keepAlive(socket) }
        defer {
            keepAlive.cancel()
            self.socket = nil
            partnerHere = false
        }
        var inRoom = false
        do {
            while true {
                guard case .string(let text) = try await socket.receive() else { continue }
                if text == "ring" {
                    onNote?("rung: checking now")
                    onCheck?()
                } else if text.hasPrefix("here "), let count = Int(text.dropFirst(5)) {
                    if !inRoom { onNote?("connected") }
                    inRoom = true
                    if partnerHere != (count >= 2) {
                        partnerHere = count >= 2
                        onNote?(partnerHere ? "partner here too" : "partner left")
                    }
                    onCheck?()
                }
            }
        } catch {
            onNote?("\(inRoom ? "disconnected" : "couldn't connect"): \(error.diagnosticDescription)")
        }
        return inRoom
    }

    /// Pings the room now and then; no pong in time means the connection died quietly (Wi-Fi changed,
    /// the Mac slept), so drop it and reconnect. Cloudflare answers pings without waking the room.
    private func keepAlive(_ socket: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            try? await Task.sleep(for: Config.Live.keepAlive)
            let sent = Date.now
            socket.sendPing { [weak self] error in
                guard error == nil else { return }
                Task { @MainActor in self?.lastPong = .now }
            }
            try? await Task.sleep(for: Config.Live.pongWait)
            if !Task.isCancelled, lastPong < sent {
                onNote?("no answer to keep-alive")
                socket.cancel(with: .goingAway, reason: nil)
            }
        }
    }
}
