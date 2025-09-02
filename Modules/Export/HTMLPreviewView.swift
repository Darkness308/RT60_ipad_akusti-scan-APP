#if canImport(SwiftUI) && canImport(WebKit)
import SwiftUI
import WebKit

public struct HTMLPreviewView: UIViewRepresentable {
    let htmlData: Data
    public init(htmlData: Data) { self.htmlData = htmlData }

    public func makeUIView(context: Context) -> WKWebView {
        let conf = WKWebViewConfiguration()
        let v = WKWebView(frame: .zero, configuration: conf)
        v.backgroundColor = .white
        v.isOpaque = false
        v.scrollView.contentInset = .init(top: 8, left: 0, bottom: 8, right: 0)
        return v
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        let html = String(decoding: htmlData, as: UTF8.self)
        webView.loadHTMLString(html, baseURL: nil)
    }
}
#endif