import SwiftUI
import WebKit

// MARK: - Patient Dashboard
struct PatientDashboardView: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if auth.isLoggedIn {
            authenticatedDashboard
        } else {
            NativeLoginForm()
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Authenticated — WebView a ecrã cheio
    private var authenticatedDashboard: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            AuthenticatedWebView(
                url: KayaConfig.dashboardURL,
                token: auth.token() ?? ""
            )
            .ignoresSafeArea(edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // deixar espaço para a topBar nativa
            .padding(.top, topBarHeight)

            // Barra nativa sobreposta
            VStack(spacing: 0) {
                topBar
                Divider().opacity(0.4)
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .bottom)
    }

    private var topBarHeight: CGFloat { 52 }

    private var topBar: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Text("Fechar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "2D8C82"))
            }
            .frame(width: 80, alignment: .leading)
            .padding(.leading, 16)

            Spacer()

            VStack(spacing: 2) {
                Text("Painel")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "101828"))
                if let name = auth.profile?.full_name ?? auth.profile?.email {
                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "2D8C82"))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button { auth.logout(); dismiss() } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "EF4444"))
            }
            .frame(width: 80, alignment: .trailing)
            .padding(.trailing, 16)
        }
        .frame(height: topBarHeight)
        .background(.ultraThinMaterial)
    }
}

// MARK: - WKWebView with JWT
struct AuthenticatedWebView: UIViewRepresentable {
    let url: URL
    let token: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // 1. Forçar viewport mobile + injectar JWT
        let js = """
        (function() {
            // Viewport mobile correcto
            var existing = document.querySelector('meta[name="viewport"]');
            if (!existing) {
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head && document.head.appendChild(meta);
            } else {
                existing.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            }
            // Auth
            try {
                localStorage.setItem('access_token', '\(token)');
                localStorage.setItem('token', '\(token)');
                document.cookie = 'access_token=\(token); path=/; SameSite=Lax';
            } catch(e) {}
        })();
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        config.websiteDataStore = .default()

        // 2. Preferência de viewport nativa do WKWebView
        let webpagePrefs = WKWebpagePreferences()
        config.defaultWebpagePreferences = webpagePrefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.backgroundColor = .white
        webView.isOpaque = true
        // Forçar mobile user-agent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            var req = URLRequest(url: url)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            webView.load(req)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

// MARK: - Native Login Form
struct NativeLoginForm: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var email    = ""
    @State private var password = ""
    @State private var showDashboard = false
    @FocusState private var focus: Field?
    enum Field { case email, password }

    var body: some View {
        ZStack {
            Color(hex: "F7FAFC").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Botão fechar próprio (sem barra nativa)
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(hex: "667085"))
                                .frame(width: 36, height: 36)
                                .background(Color(hex: "F2F4F7"))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.top, 8)

                    // Logo
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: [Color(hex: "2D8C82"), Color(hex: "55B7A8")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .shadow(color: Color(hex: "2D8C82").opacity(0.3), radius: 16, x: 0, y: 8)

                        Text("KAYA Health")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(Color(hex: "101828"))

                        Text("Entra com a tua conta para ver o painel de saúde.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "5D6B82"))
                            .multilineTextAlignment(.center)
                    }

                    // Form
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Email")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "475467"))
                        TextField("email@exemplo.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focus, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focus = .password }
                            .loginFieldStyle()

                        Text("Palavra-passe")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "475467"))
                        SecureField("••••••••", text: $password)
                            .focused($focus, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { loginAction() }
                            .loginFieldStyle()

                        if let err = auth.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(err)
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.red)
                            .padding(12)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)

                    // CTA
                    Button { loginAction() } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Entrar no painel", systemImage: "arrow.right.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSubmit ? Color(hex: "2D8C82") : Color(hex: "A0C8C2"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 6)
                    }
                    .disabled(!canSubmit || auth.isLoading)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .fullScreenCover(isPresented: $showDashboard) {
            PatientDashboardView()
        }
        .onChange(of: auth.isLoggedIn) { loggedIn in
            if loggedIn { showDashboard = true }
        }
    }

    private var canSubmit: Bool { !email.isEmpty && password.count >= 4 }

    private func loginAction() {
        focus = nil
        guard canSubmit else { return }
        Task { await auth.login(email: email, password: password) }
    }
}

// MARK: - Input Style
private extension View {
    func loginFieldStyle() -> some View {
        self
            .padding(14)
            .background(Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "D0D5DD"), lineWidth: 1))
    }
}
