import SwiftUI
import WebKit
import FamilyControls

/// Connects the BrightSprout web app to iPhone Screen Time.
///
/// Web app -> native (window.BrightSproutNative.post / .call):
///   ready, authorize {mode}, pickApps, sync {on, kidId, kidName, limit, extra}, parentUnlock, changePin
/// Native -> web: window.BrightSproutNative._receive({type:"status", data:{...}})
@MainActor
final class NativeBridge: NSObject, ObservableObject, WKScriptMessageHandler {
    static let handlerName = "brightsprout"

    weak var webView: WKWebView?

    @Published var showPicker = false
    @Published var pickerSelection = FamilyActivitySelection()
    @Published var showPin = false

    /// What the PIN sheet is for, and which web callback is waiting for the answer.
    private(set) var pinIsChange = false
    private var pinCallbackId: String?

    private var lastError = ""

    // MARK: Messages from the web app

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        let callbackId = body["callbackId"] as? String

        switch type {
        case "ready":
            if isAuthorized { ScreenTimeEngine.refreshIfNeeded() }
            sendStatus()
        case "authorize":
            let child = (body["mode"] as? String) != "individual"
            Task { await authorize(child: child) }
        case "pickApps":
            pickerSelection = ScreenTimeEngine.selection
            showPicker = true
        case "sync":
            applySync(body)
        case "parentUnlock":
            askForPin(change: false, callbackId: callbackId)
        case "changePin":
            askForPin(change: true, callbackId: callbackId)
        default:
            break
        }
    }

    // MARK: Screen Time

    private var isAuthorized: Bool {
        AuthorizationCenter.shared.authorizationStatus == .approved
    }

    private func authorize(child: Bool) async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: child ? .child : .individual)
            SharedState.authMode = child ? "child" : "individual"
            lastError = ""
            ScreenTimeEngine.refreshSchedule()
        } catch {
            lastError = child
                ? "Screen Time permission wasn't given. On a child's iPhone, the child must be in your Family Sharing group and a parent signs in to approve. (\(error.localizedDescription))"
                : "Screen Time permission wasn't given. (\(error.localizedDescription))"
        }
        sendStatus()
    }

    private func applySync(_ body: [String: Any]) {
        let on = body["on"] as? Bool ?? false
        let limit = (body["limit"] as? NSNumber)?.intValue ?? 60
        let extra = (body["extra"] as? NSNumber)?.intValue ?? 0

        SharedState.kidId = body["kidId"] as? String
        SharedState.kidName = body["kidName"] as? String

        let changed = on != SharedState.enabled
            || limit != SharedState.limitMinutes
            || extra != SharedState.extraMinutes
        if extra > SharedState.extraMinutes { SharedState.clearAsked() }

        SharedState.enabled = on
        SharedState.limitMinutes = limit
        SharedState.setExtraMinutes(extra)

        if changed && isAuthorized { ScreenTimeEngine.refreshSchedule() }
        sendStatus()
    }

    func pickerClosed() {
        ScreenTimeEngine.selection = pickerSelection
        if isAuthorized { ScreenTimeEngine.refreshSchedule() }
        sendStatus()
    }

    func appBecameActive() {
        guard webView != nil else { return }
        if isAuthorized { ScreenTimeEngine.refreshIfNeeded() }
        sendStatus()
    }

    // MARK: Parent PIN

    private func askForPin(change: Bool, callbackId: String?) {
        pinIsChange = change
        pinCallbackId = callbackId
        showPin = true
    }

    /// Called by the PIN sheet when the parent got the PIN right (or set a new one).
    func pinFinished(ok: Bool) {
        if let id = pinCallbackId {
            send(["type": "callback", "callbackId": id, "ok": ok])
        }
        pinCallbackId = nil
        showPin = false
    }

    func pinSheetDismissed() {
        if pinCallbackId != nil { pinFinished(ok: false) }
    }

    // MARK: Native -> web

    func sendStatus() {
        let s = ScreenTimeEngine.selection
        var supportsPastActivity = false
        if #available(iOS 17.4, *) { supportsPastActivity = true }
        let error = lastError.isEmpty ? SharedState.lastError : lastError
        let status: [String: Any] = [
            "authorized": isAuthorized,
            "mode": SharedState.authMode,
            "apps": s.applicationTokens.count,
            "categories": s.categoryTokens.count,
            "sites": s.webDomainTokens.count,
            "enabled": SharedState.enabled,
            "kidId": SharedState.kidId ?? "",
            "allowed": SharedState.allowedMinutesToday,
            "blocked": SharedState.blockedToday,
            "blockedAt": SharedState.blockedAtMinutes,
            "asked": SharedState.askedForMoreToday,
            "hasPin": ParentPin.isSet,
            "accurateRestart": supportsPastActivity,
            "error": error,
        ]
        send(["type": "status", "data": status])
    }

    private func send(_ message: [String: Any]) {
        guard let webView,
              let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.BrightSproutNative && window.BrightSproutNative._receive(\(json))")
    }

    /// Injected before the web app loads, so it knows it is running inside the iPhone app.
    static let bootstrapJS = """
    (function(){
      var waiting = {}, n = 0;
      var N = window.BrightSproutNative = {
        available: true,
        status: null,
        post: function(type, data){
          var m = {type: type}; data = data || {};
          for (var k in data) m[k] = data[k];
          window.webkit.messageHandlers.\(handlerName).postMessage(m);
        },
        call: function(type, data){
          return new Promise(function(resolve){
            var id = 'c' + (++n); waiting[id] = resolve;
            var d = data || {}; d.callbackId = id; N.post(type, d);
          });
        },
        _receive: function(msg){
          if (msg.type === 'callback' && waiting[msg.callbackId]) { waiting[msg.callbackId](msg); delete waiting[msg.callbackId]; }
          if (msg.type === 'status') { N.status = msg.data; window.dispatchEvent(new CustomEvent('bsnative', {detail: msg.data})); }
        }
      };
    })();
    """
}
