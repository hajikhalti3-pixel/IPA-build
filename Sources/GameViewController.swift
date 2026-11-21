import UIKit
import WebKit
import GameController

/// Hosts the game page and does what Minecraft does on desktop: it locks the pointer and reads the RAW mouse
/// movement (GameController), so turning never stops at a screen edge. The movement is handed to the page
/// (window.eaglerNative) which feeds it to the game.
final class GameViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {

    private var web: WKWebView!
    private var wantLock = true            // the page turns this off while its settings panel is open
    private var dx: CGFloat = 0, dy: CGFloat = 0, wheel: CGFloat = 0
    private var buttons: [(Int, Bool)] = []
    private var link: CADisplayLink?

    // If the camera / cursor moves up when you move the mouse down, change this to false.
    private let mouseYIsUp = true

    // MARK: - UIKit overrides
    override var prefersPointerLocked: Bool { wantLock }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var canBecomeFirstResponder: Bool { true }

    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let cfg = WKWebViewConfiguration()
        cfg.userContentController.add(self, name: "eaglerNative")
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.allowsInlineMediaPlayback = true

        web = WKWebView(frame: view.bounds, configuration: cfg)
        web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        web.navigationDelegate = self
        web.backgroundColor = .black
        web.isOpaque = true
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(web)

        if let url = Bundle.main.url(forResource: "game", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        NotificationCenter.default.addObserver(self, selector: #selector(mouseConnected(_:)),
                                               name: .GCMouseDidConnect, object: nil)
        for m in GCMouse.mice() { attach(m) }

        link = CADisplayLink(target: self, selector: #selector(flush))
        link?.add(to: .main, forMode: .common)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        web.becomeFirstResponder()
        setNeedsUpdateOfPrefersPointerLocked()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.becomeFirstResponder()
    }

    // MARK: - Page -> app
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let d = message.body as? [String: Any], let lock = d["lock"] as? Bool, lock != wantLock {
            wantLock = lock
            setNeedsUpdateOfPrefersPointerLocked()
        }
    }

    // MARK: - Raw mouse (GameController)
    @objc private func mouseConnected(_ note: Notification) {
        if let m = note.object as? GCMouse { attach(m) }
    }

    private func attach(_ mouse: GCMouse) {
        guard let input = mouse.mouseInput else { return }
        input.mouseMovedHandler = { [weak self] _, x, y in
            guard let self = self, self.wantLock else { return }
            self.dx += CGFloat(x)
            self.dy += CGFloat(self.mouseYIsUp ? -y : y)
        }
        input.leftButton.pressedChangedHandler = { [weak self] _, _, pressed in self?.queue(0, pressed) }
        input.rightButton?.pressedChangedHandler = { [weak self] _, _, pressed in self?.queue(2, pressed) }
        input.middleButton?.pressedChangedHandler = { [weak self] _, _, pressed in self?.queue(1, pressed) }
        input.scroll.valueChangedHandler = { [weak self] _, _, y in
            guard let self = self, self.wantLock else { return }
            self.wheel += CGFloat(y)
        }
    }

    private func queue(_ button: Int, _ pressed: Bool) {
        guard wantLock else { return }
        buttons.append((button, pressed))
    }

    // MARK: - App -> page (once per screen refresh, so a fast mouse does not flood the web view)
    @objc private func flush() {
        var js = ""
        if dx != 0 || dy != 0 { js += "eaglerNative.move(\(dx),\(dy));"; dx = 0; dy = 0 }
        for (b, down) in buttons { js += "eaglerNative.button(\(b),\(down));" }
        buttons.removeAll()
        if wheel != 0 { js += "eaglerNative.wheel(\(wheel));"; wheel = 0 }
        if !js.isEmpty {
            web.evaluateJavaScript("window.eaglerNative&&(function(){\(js)})();", completionHandler: nil)
        }
    }
}
