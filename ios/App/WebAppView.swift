import SwiftUI
import WebKit

/// Shows the full BrightSprout web app (the same index.html as the website),
/// bundled inside the app so it works offline.
struct WebAppView: UIViewRepresentable {
    let bridge: NativeBridge

    /// The page runs as if it were served from the website, so saved progress,
    /// YouTube videos and links behave the same as in Safari.
    static let baseURL = URL(string: "https://mishrasanjayk.github.io/brightsprout/")!

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default() // keeps Stars and progress between launches

        let content = config.userContentController
        content.add(bridge, name: NativeBridge.handlerName)
        content.addUserScript(WKUserScript(source: NativeBridge.bootstrapJS,
                                           injectionTime: .atDocumentStart,
                                           forMainFrameOnly: true))

        let web = WKWebView(frame: .zero, configuration: config)
        web.scrollView.contentInsetAdjustmentBehavior = .never // the page handles safe areas itself
        web.isOpaque = false
        web.backgroundColor = .systemBackground
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        bridge.webView = web

        if let file = Bundle.main.url(forResource: "index", withExtension: "html"),
           let html = try? String(contentsOf: file, encoding: .utf8) {
            web.loadHTMLString(html, baseURL: Self.baseURL)
        } else {
            web.load(URLRequest(url: Self.baseURL))
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        // Links that open a new tab (YouTube "Watch", "Open in YouTube") go to Safari or the YouTube app.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url { UIApplication.shared.open(url) }
            return nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? false
            // Keep the app itself in place; open other pages outside the app.
            if isMainFrame, navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        // Camera and microphone for video proof.
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.prompt)
        }
    }
}
