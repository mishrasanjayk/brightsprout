import SwiftUI
import FamilyControls

@main
struct BrightSproutApp: App {
    @StateObject private var bridge = NativeBridge()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WebAppView(bridge: bridge)
                .ignoresSafeArea()
                .familyActivityPicker(isPresented: $bridge.showPicker, selection: $bridge.pickerSelection)
                .onChange(of: bridge.showPicker) { shown in
                    if !shown { bridge.pickerClosed() }
                }
                .sheet(isPresented: $bridge.showPin, onDismiss: { bridge.pinSheetDismissed() }) {
                    ParentPinView(bridge: bridge)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active { bridge.appBecameActive() }
                }
        }
    }
}
