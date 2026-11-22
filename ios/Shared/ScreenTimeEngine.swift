import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

extension ManagedSettingsStore.Name {
    static let brightSprout = Self("brightsprout")
}

extension DeviceActivityName {
    static let brightSproutDaily = Self("brightsprout.daily")
}

extension DeviceActivityEvent.Name {
    static let brightSproutLimit = Self("brightsprout.limitReached")
}

/// Turns BrightSprout's daily limit into real Screen Time blocking.
///
/// How it works:
/// 1. A repeating schedule runs from midnight to midnight.
/// 2. One event fires when the chosen apps have been used for the day's allowance
///    (daily limit + extra minutes earned today).
/// 3. The monitor extension then "shields" (blocks) those apps.
/// 4. When a parent grants more minutes, the shield comes off and the event is
///    registered again with the bigger allowance.
enum ScreenTimeEngine {
    static var selection: FamilyActivitySelection {
        get {
            guard let data = SharedState.selectionData,
                  let s = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { return FamilyActivitySelection() }
            return s
        }
        set { SharedState.selectionData = try? JSONEncoder().encode(newValue) }
    }

    static var hasSelection: Bool {
        let s = selection
        return !(s.applicationTokens.isEmpty && s.categoryTokens.isEmpty && s.webDomainTokens.isEmpty)
    }

    static func applyShield() {
        let s = selection
        let store = ManagedSettingsStore(named: .brightSprout)
        store.shield.applications = s.applicationTokens.isEmpty ? nil : s.applicationTokens
        store.shield.applicationCategories = s.categoryTokens.isEmpty ? nil : .specific(s.categoryTokens)
        store.shield.webDomains = s.webDomainTokens.isEmpty ? nil : s.webDomainTokens
        store.shield.webDomainCategories = s.categoryTokens.isEmpty ? nil : .specific(s.categoryTokens)
    }

    static func removeShield() {
        ManagedSettingsStore(named: .brightSprout).clearAllSettings()
    }

    /// Re-register only when today's allowance changed (new day, more minutes, new limit).
    static func refreshIfNeeded() {
        if SharedState.registeredAllowed != SharedState.allowedMinutesToday || !SharedState.enabled {
            refreshSchedule()
        }
    }

    /// (Re)start daily monitoring with today's allowance. Safe to call often.
    static func refreshSchedule() {
        let center = DeviceActivityCenter()
        center.stopMonitoring([.brightSproutDaily])

        guard SharedState.enabled, hasSelection else {
            removeShield()
            SharedState.clearBlocked()
            SharedState.registeredAllowed = 0
            return
        }

        let allowed = SharedState.allowedMinutesToday
        if SharedState.blockedToday {
            if allowed > SharedState.blockedAtMinutes {
                // A parent granted more time: unblock now.
                SharedState.clearBlocked()
                SharedState.clearAsked()
                removeShield()
            } else {
                applyShield() // still out of time (also picks up a changed app list)
            }
        } else {
            removeShield()
        }

        let s = selection
        let event: DeviceActivityEvent
        if #available(iOS 17.4, *) {
            // Counts usage from midnight, so re-registering mid-day stays accurate.
            event = DeviceActivityEvent(
                applications: s.applicationTokens,
                categories: s.categoryTokens,
                webDomains: s.webDomainTokens,
                threshold: minutes(allowed),
                includesPastActivity: true
            )
        } else {
            // Older iOS counts from the moment monitoring starts, so subtract what we
            // know was already used (the allowance at the last block today).
            let remaining = max(1, allowed - SharedState.blockedAtMinutes)
            event = DeviceActivityEvent(
                applications: s.applicationTokens,
                categories: s.categoryTokens,
                webDomains: s.webDomainTokens,
                threshold: minutes(remaining)
            )
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(.brightSproutDaily, during: schedule, events: [.brightSproutLimit: event])
            SharedState.registeredAllowed = allowed
            SharedState.lastError = ""
        } catch {
            SharedState.lastError = "Could not start Screen Time monitoring: \(error.localizedDescription)"
        }
    }

    private static func minutes(_ m: Int) -> DateComponents {
        DateComponents(hour: m / 60, minute: m % 60)
    }
}
