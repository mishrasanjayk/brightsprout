import ManagedSettings
import ManagedSettingsUI
import UIKit

/// The screen a kid sees when they open a blocked app. It matches the web app's lock screen.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration { make() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { make() }

    private func make() -> ShieldConfiguration {
        let leaf = UIColor(red: 0.18, green: 0.62, blue: 0.36, alpha: 1)
        let name = SharedState.kidName.flatMap { $0.isEmpty ? nil : $0 } ?? "friend"
        let asked = SharedState.askedForMoreToday
        let subtitle = asked
            ? "You asked a parent for more time. Open BrightSprout to earn Stars while you wait."
            : "Great job today, \(name)! Your screen time is used up. Earn Stars in BrightSprout, or ask a parent for more time."
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor(red: 0.94, green: 0.98, blue: 0.94, alpha: 1),
            icon: UIImage(systemName: "moon.stars.fill"),
            title: ShieldConfiguration.Label(text: "Screen time is done for today", color: .label),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: asked ? "OK" : "Ask a parent for more time", color: .white),
            primaryButtonBackgroundColor: leaf,
            secondaryButtonLabel: asked ? nil : ShieldConfiguration.Label(text: "OK", color: leaf)
        )
    }
}
