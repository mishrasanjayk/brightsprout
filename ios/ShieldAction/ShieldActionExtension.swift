import ManagedSettings
import Foundation

/// Handles the buttons on the block screen.
class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    private func respond(to action: ShieldAction, _ done: (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            if SharedState.askedForMoreToday {
                done(.close)
            } else {
                // The request shows up in BrightSprout's Parent > Approve tab.
                SharedState.markAsked()
                done(.defer) // keep the shield up and redraw it with "You asked a parent"
            }
        case .secondaryButtonPressed:
            done(.close)
        @unknown default:
            done(.close)
        }
    }
}
