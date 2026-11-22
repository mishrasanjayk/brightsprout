import Foundation

/// The App Group lets the app and its Screen Time extensions read the same settings.
enum AppGroup {
    static let id: String =
        (Bundle.main.object(forInfoDictionaryKey: "BSAppGroupID") as? String) ?? "group.com.yourname.brightsprout"
    static let defaults: UserDefaults = UserDefaults(suiteName: id) ?? .standard
}

/// Blocking settings and today's status, shared by the app and all extensions.
/// "Today" always means the phone's local calendar day.
enum SharedState {
    private static var d: UserDefaults { AppGroup.defaults }

    static func todayKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: Settings (sent from the BrightSprout web app)

    /// True when a parent turned on the screen time link and picked which child uses this iPhone.
    static var enabled: Bool {
        get { d.bool(forKey: "enabled") }
        set { d.set(newValue, forKey: "enabled") }
    }

    static var limitMinutes: Int {
        get { let v = d.integer(forKey: "limitMinutes"); return v > 0 ? v : 60 }
        set { d.set(max(1, newValue), forKey: "limitMinutes") }
    }

    /// Extra minutes earned or granted today (Stars, rewards, goals, "+15 min").
    static var extraMinutes: Int {
        d.string(forKey: "extraDay") == todayKey() ? d.integer(forKey: "extraMinutes") : 0
    }

    static func setExtraMinutes(_ minutes: Int) {
        d.set(max(0, minutes), forKey: "extraMinutes")
        d.set(todayKey(), forKey: "extraDay")
    }

    static var allowedMinutesToday: Int { limitMinutes + extraMinutes }

    static var kidId: String? {
        get { d.string(forKey: "kidId") }
        set { d.set(newValue, forKey: "kidId") }
    }

    static var kidName: String? {
        get { d.string(forKey: "kidName") }
        set { d.set(newValue, forKey: "kidName") }
    }

    /// "child" (Family Sharing, a parent approves) or "individual" (testing on your own phone).
    static var authMode: String {
        get { d.string(forKey: "authMode") ?? "" }
        set { d.set(newValue, forKey: "authMode") }
    }

    /// The apps, categories and websites the parent chose (encoded FamilyActivitySelection).
    static var selectionData: Data? {
        get { d.data(forKey: "selection") }
        set { d.set(newValue, forKey: "selection") }
    }

    // MARK: Today's status (written by the extensions)

    static var blockedToday: Bool { d.string(forKey: "blockedDay") == todayKey() }

    /// The allowance (in minutes) that had been used up when apps were last blocked today.
    static var blockedAtMinutes: Int {
        d.string(forKey: "usedFloorDay") == todayKey() ? d.integer(forKey: "usedFloor") : 0
    }

    static func markBlocked(allowedMinutes: Int) {
        d.set(todayKey(), forKey: "blockedDay")
        d.set(allowedMinutes, forKey: "usedFloor")
        d.set(todayKey(), forKey: "usedFloorDay")
    }

    static func clearBlocked() { d.removeObject(forKey: "blockedDay") }

    /// Set when the kid taps "Ask a parent" on the block screen.
    static var askedForMoreToday: Bool { d.string(forKey: "askedDay") == todayKey() }
    static func markAsked() { d.set(todayKey(), forKey: "askedDay") }
    static func clearAsked() { d.removeObject(forKey: "askedDay") }

    /// The allowance the current schedule was registered with, so we know when to re-register.
    static var registeredAllowed: Int {
        get { d.string(forKey: "registeredDay") == todayKey() ? d.integer(forKey: "registeredAllowed") : -1 }
        set { d.set(newValue, forKey: "registeredAllowed"); d.set(todayKey(), forKey: "registeredDay") }
    }

    static var lastError: String {
        get { d.string(forKey: "lastError") ?? "" }
        set { d.set(newValue, forKey: "lastError") }
    }
}
