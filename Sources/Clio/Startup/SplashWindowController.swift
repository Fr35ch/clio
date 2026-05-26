import AppKit
import SwiftUI
import WebKit

@MainActor
final class SplashWindowController {

    var window: NSWindow?
    var onDismiss: (() -> Void)?

    func show(coordinator: StartupCoordinator) {
        let w = makeWindow()
        let container = RoundedContainerView(frame: NSRect(x: 0, y: 0, width: 680, height: 420))

        // WKWebView renders the SVG reliably — NSImage cannot handle
        // gradientUnits="userSpaceOnUse" at large coordinate spaces.
        // SVG is inlined as a literal so rendering is never bundle-dependent.
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = true
        let webView = WKWebView(frame: container.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")  // transparent WKWebView background
        // WKWebView on macOS is backed by an NSScrollView. Disable scrolling and
        // zero out content insets so the SVG fills the frame without any offset.
        if let scrollView = webView.enclosingScrollView {
            scrollView.hasHorizontalScroller = false
            scrollView.hasVerticalScroller   = false
            scrollView.horizontalScrollElasticity = .none
            scrollView.verticalScrollElasticity   = .none
            scrollView.contentInsets = .zero
            scrollView.automaticallyAdjustsContentInsets = false
        }
        let svgString = SplashBackground.svg
        let html = """
        <html><head><style>
        * { margin: 0; padding: 0; }
        html, body { width: 100%; height: 100%; overflow: hidden; background: #8347F0; }
        svg { width: 100%; height: 100%; display: block; }
        </style></head><body>\(svgString)</body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
        container.addSubview(webView)

        let host = NSHostingView(rootView:
            SplashView(coordinator: coordinator) { [weak self] in self?.dismiss() }
        )
        host.frame             = container.bounds
        host.autoresizingMask  = [.width, .height]
        host.wantsLayer        = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        container.addSubview(host)

        w.contentView = container
        w.center()
        w.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async { w.invalidateShadow() }
        window = w
    }

    func dismiss() {
        let win      = window
        let callback = onDismiss
        window    = nil
        onDismiss = nil
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration       = 0.42
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            win?.animator().alphaValue = 0
        }, completionHandler: {
            win?.orderOut(nil)
            callback?()
        })
    }

    private func makeWindow() -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
            styleMask:   [.borderless, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        w.isOpaque                    = false
        w.backgroundColor             = .clear
        w.hasShadow                   = true
        w.isMovableByWindowBackground = true
        w.level                       = .floating
        w.titlebarAppearsTransparent  = true
        w.titleVisibility             = .hidden
        w.animationBehavior           = .none   // fix 1 — disables macOS fade-in
        w.alphaValue                  = 1.0     // fix 1 — explicit full opacity
        w.isRestorable                = false   // fix 2 — prevents session restoration
        return w
    }
}

private final class RoundedContainerView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer               = true
        layer?.cornerRadius      = 28
        layer?.cornerCurve       = .continuous
        layer?.masksToBounds     = true
        layer?.backgroundColor   = NSColor.black.cgColor
        autoresizingMask         = [.width, .height]
    }
    required init?(coder: NSCoder) { fatalError() }
}
