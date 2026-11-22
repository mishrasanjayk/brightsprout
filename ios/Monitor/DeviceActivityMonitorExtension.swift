import DeviceActivity
import Foundation

/// Runs in the background, even when BrightSprout is closed.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity == .brightSproutDaily else { return }
        // A new day: unlock everything. Yesterday's extra minutes no longer count,
        // so register today's event with just the daily limit.
        if !SharedState.blockedToday {
            ScreenTimeEngine.removeShield()
        }
        ScreenTimeEngine.refreshIfNeeded()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event == .brightSproutLimit, SharedState.enabled else { return }
        SharedState.markBlocked(allowedMinutes: SharedState.allowedMinutesToday)
        ScreenTimeEngine.applyShield()
    }
}
