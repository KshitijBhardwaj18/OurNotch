import Foundation

/// Keeps messages short enough for the notch banner (`prd.md > Sending Messages`).
enum MessageRules {
    enum Verdict: Equatable {
        /// Ready to send, with surrounding whitespace trimmed.
        case valid(String)
        /// Nothing to send yet; no hint needed.
        case empty
        /// Over a limit; show the gentle hint.
        case invalid(hint: String)
    }

    static func check(_ raw: String) -> Verdict {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return .empty }

        let words = text.split(whereSeparator: \.isWhitespace)
        if words.count > Config.Message.maxWords { return .invalid(hint: "\(Config.Message.maxWords) words max ♡") }
        if text.count > Config.Message.maxCharacters { return .invalid(hint: "a little shorter ♡") }
        if words.contains(where: { $0.count > Config.Message.maxWordLength }) {
            return .invalid(hint: "one word is too long ♡")
        }
        return .valid(text)
    }
}
