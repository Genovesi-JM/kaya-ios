import SwiftUI
import WebKit

// MARK: - WebView Screen (sheet wrapper)
struct KayaWebViewScreen: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    let title: String

    var body: some View {
        NavigationStack {
            WebView(url: url)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Fechar") { dismiss() }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: "2D8C82"))
                    }
                }
        }
    }
}

// MARK: - WKWebView wrapper
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.allowsBackForwardNavigationGestures = true
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
