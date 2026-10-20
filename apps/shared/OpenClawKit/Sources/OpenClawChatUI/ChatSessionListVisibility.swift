import Foundation

/// Shared classification for automation-owned session rows in ordinary
/// navigation lists.
///
/// Mirrors the canonical web classifier in
/// `src/shared/session-list-visibility.ts` and the native Android adapter
/// predicate in the Sessions screen (`isAutomationSession`): automation and
/// cron sessions stay out of default lists while remaining discoverable
/// through a dedicated automations scope and search. Display classification
/// only; routing still validates canonical session keys separately.
public enum OpenClawChatSessionListVisibility {
    /// Display keys historically ignore empty segments and accept whitespace
    /// owners; match the shared web classifier's cron-key shape directly.
    private static let cronDisplayKeyRegex: NSRegularExpression = {
        let pattern = "^(?:cron:|agent::*[^:]+:+cron:+[^:])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            preconditionFailure("Invalid cron display key regex: \(pattern)")
        }
        return regex
    }()

    /// - SeeAlso: `isCronSessionDisplayKey` in `src/shared/session-list-visibility.ts`.
    public static func isCronSessionDisplayKey(_ key: String) -> Bool {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return false }
        let range = NSRange(normalized.startIndex..., in: normalized)
        return self.cronDisplayKeyRegex.firstMatch(in: normalized, range: range) != nil
    }

    /// Cron rows belong to the automations scope; system-created rows and
    /// unbranded run/internal provenance belong to it too. Legacy rows without
    /// either and operator-named CLI sessions stay discoverable as chats.
    public static func isAutomationSession(_ entry: OpenClawChatSessionEntry) -> Bool {
        if Self.isCronSessionDisplayKey(entry.key) || entry.createdActor?.type == "system" {
            return true
        }
        guard entry.createdVia == "run" || entry.createdVia == "internal",
              entry.createdActor?.type != "human"
        else { return false }
        return Self.isBlank(entry.label) && Self.isBlank(entry.displayName)
            && Self.isBlank(entry.subject)
    }

    /// Ordinary navigation lists keep the selected session reachable even when
    /// it is automation-created, mirroring the Android navigation predicate.
    public static func isVisibleInNavigation(
        _ entry: OpenClawChatSessionEntry,
        currentSessionKey: String) -> Bool {
        entry.key == currentSessionKey
            || (entry.archived != true && !Self.isAutomationSession(entry))
    }

    private static func isBlank(_ value: String?) -> Bool {
        guard let value else { return true }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
