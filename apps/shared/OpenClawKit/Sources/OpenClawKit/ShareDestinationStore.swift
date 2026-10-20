import Foundation

/// A chat the share sheet can route a share into. Written by the host app from
/// its session list (main + pinned) and read by the Share Extension.
public struct ShareDestination: Codable, Sendable, Equatable {
    public let sessionKey: String
    public let title: String

    public init(sessionKey: String, title: String) {
        self.sessionKey = sessionKey
        self.title = title
    }
}

/// One selectable row in the extension's destination picker.
public struct ShareDestinationOption: Sendable, Equatable {
    public let destination: ShareDestination
    public let isMain: Bool

    public init(destination: ShareDestination, isMain: Bool) {
        self.destination = destination
        self.isMain = isMain
    }
}

/// App-group snapshot of share destinations plus the last-used selection.
/// Credentials never live here; this is routing metadata only.
public enum ShareDestinationStore {
    private static let destinationsKey = "share.gatewayRelay.destinations.v1"
    private static let lastSelectedKey = "share.gatewayRelay.lastDestination.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: OpenClawAppGroup.identifier) ?? .standard
    }

    public static func saveDestinations(_ destinations: [ShareDestination]) {
        self.saveDestinations(destinations, defaults: self.defaults)
    }

    public static func loadDestinations() -> [ShareDestination] {
        self.loadDestinations(defaults: self.defaults)
    }

    public static func saveLastSelectedSessionKey(_ sessionKey: String) {
        self.saveLastSelectedSessionKey(sessionKey, defaults: self.defaults)
    }

    public static func loadLastSelectedSessionKey() -> String? {
        self.loadLastSelectedSessionKey(defaults: self.defaults)
    }

    // Injectable variants keep the store testable without touching shared state.

    static func saveDestinations(_ destinations: [ShareDestination], defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(destinations) else { return }
        defaults.set(data, forKey: self.destinationsKey)
    }

    static func loadDestinations(defaults: UserDefaults) -> [ShareDestination] {
        guard let data = defaults.data(forKey: self.destinationsKey) else { return [] }
        return (try? JSONDecoder().decode([ShareDestination].self, from: data)) ?? []
    }

    static func saveLastSelectedSessionKey(_ sessionKey: String, defaults: UserDefaults) {
        defaults.set(sessionKey, forKey: self.lastSelectedKey)
    }

    static func loadLastSelectedSessionKey(defaults: UserDefaults) -> String? {
        defaults.string(forKey: self.lastSelectedKey)
    }
}

/// Pure ordering and selection rules for the destination picker, kept free of
/// UIKit and storage so hosts, extensions, and tests agree on one contract.
public enum ShareDestinationCatalog {
    /// Main chat first, then stored destinations in host-provided order.
    /// Stored entries duplicating the main session key are dropped; the main
    /// entry is always present even when the stored snapshot is empty.
    public static func options(
        configSessionKey: String,
        stored: [ShareDestination]) -> [ShareDestinationOption]
    {
        let main = ShareDestination(sessionKey: configSessionKey, title: "")
        var options = [ShareDestinationOption(destination: main, isMain: true)]
        for destination in stored where destination.sessionKey != configSessionKey {
            options.append(ShareDestinationOption(destination: destination, isMain: false))
        }
        return options
    }

    /// The row to preselect: the last-used destination when it is still
    /// offered, otherwise main. Empty/unknown stored selections fall back.
    public static func resolveSelectedIndex(
        options: [ShareDestinationOption],
        lastUsedSessionKey: String?) -> Int?
    {
        guard !options.isEmpty else { return nil }
        if let lastUsedSessionKey, !lastUsedSessionKey.isEmpty,
           let index = options.firstIndex(where: { $0.destination.sessionKey == lastUsedSessionKey })
        {
            return index
        }
        return 0
    }
}
