import Foundation
import Testing
@testable import OpenClawKit

struct ShareDestinationStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "test.share-destinations.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func `destinations round trip through defaults`() {
        let defaults = self.makeDefaults()
        let destinations = [
            ShareDestination(sessionKey: "agent:main:pinned-1", title: "Research"),
            ShareDestination(sessionKey: "agent:main:pinned-2", title: "Ops"),
        ]

        ShareDestinationStore.saveDestinations(destinations, defaults: defaults)
        let loaded = ShareDestinationStore.loadDestinations(defaults: defaults)

        #expect(loaded == destinations)
    }

    @Test func `corrupt destination payload loads as empty`() {
        let defaults = self.makeDefaults()
        defaults.set(Data("not json".utf8), forKey: "share.gatewayRelay.destinations.v1")

        let loaded = ShareDestinationStore.loadDestinations(defaults: defaults)

        #expect(loaded.isEmpty)
    }

    @Test func `last selected session key round trips`() {
        let defaults = self.makeDefaults()

        let initial = ShareDestinationStore.loadLastSelectedSessionKey(defaults: defaults)
        ShareDestinationStore.saveLastSelectedSessionKey("agent:main:pinned-1", defaults: defaults)
        let loaded = ShareDestinationStore.loadLastSelectedSessionKey(defaults: defaults)

        #expect(initial == nil)
        #expect(loaded == "agent:main:pinned-1")
    }
}

struct ShareDestinationCatalogTests {
    private func makeOptions() -> [ShareDestinationOption] {
        ShareDestinationCatalog.options(
            configSessionKey: "agent:main:main",
            stored: [
                ShareDestination(sessionKey: "agent:main:research", title: "Research"),
                ShareDestination(sessionKey: "agent:main:ops", title: "Ops"),
            ])
    }

    @Test func `main is always first and stored duplicates are dropped`() {
        let options = ShareDestinationCatalog.options(
            configSessionKey: "agent:main:main",
            stored: [
                ShareDestination(sessionKey: "agent:main:main", title: "Main"),
                ShareDestination(sessionKey: "agent:main:research", title: "Research"),
                ShareDestination(sessionKey: "agent:main:ops", title: "Ops"),
            ])

        #expect(options.count == 3)
        #expect(options[0].isMain)
        #expect(options[0].destination.sessionKey == "agent:main:main")
        #expect(options[1].destination.title == "Research")
        #expect(options[2].destination.title == "Ops")
    }

    @Test func `empty snapshot still offers main`() {
        let options = ShareDestinationCatalog.options(configSessionKey: "agent:main:main", stored: [])

        #expect(options.count == 1)
        #expect(options[0].isMain)
    }

    @Test func `last used destination wins when still offered`() {
        let index = ShareDestinationCatalog.resolveSelectedIndex(
            options: self.makeOptions(),
            lastUsedSessionKey: "agent:main:research")

        #expect(index == 1)
    }

    @Test func `stale last used selection falls back to main`() {
        let index = ShareDestinationCatalog.resolveSelectedIndex(
            options: self.makeOptions(),
            lastUsedSessionKey: "agent:main:deleted")

        #expect(index == 0)
    }

    @Test func `no last used selection defaults to main`() {
        let index = ShareDestinationCatalog.resolveSelectedIndex(
            options: self.makeOptions(),
            lastUsedSessionKey: nil)

        #expect(index == 0)
    }

    @Test func `no options yields no selection`() {
        let index = ShareDestinationCatalog.resolveSelectedIndex(options: [], lastUsedSessionKey: nil)

        #expect(index == nil)
    }
}
