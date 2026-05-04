import SwiftUI
import WebKit

// MARK: - Patient Dashboard with Auth Session
struct PatientDashboardView: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if auth.isLoggedIn {
            authenticatedDashboard
        } else {
            NavigationStack {
                NativeLoginForm()
                    .navigationTitle("Entrar na KAYA")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // MARK: Authenticated WebView
    private var authenticatedDashboard: some View {
        ZStack(alignment: .top) {
            // WebView fundo — ignora safe area para ocupar tudo
            AuthenticatedWebView(
                url: KayaConfig.dashboardURL,
                token: auth.token() ?? ""
            )
            .ignoresSafeArea()

            // Barra nativa por cima, dentro da safe area
            VStack(spacing: 0) {
                topBar
                Divider()
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Text("Fechar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "2D8C82"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }

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

            Button {
                auth.logout()
                dismiss()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "EF4444"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .background(.white.opacity(0.97))
    }
}

// MARK: - WKWebView with JWT injected
struct AuthenticatedWebView: UIViewRepresentable {
    let url: URL
    let token: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Inject JWT into localStorage + cookie before page loads
        let js = """
        (function() {
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

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.backgroundColor = UIColor(Color(hex: "F7FAFC"))
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // Only load once
        if webView.url == nil {
            webView.load(request)
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

// MARK: - Native Login Form (real auth)
struct NativeLoginForm: View {
    @StateObject private var auth = AuthService.shared
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
                    Spacer(minLength: 20)

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
                            .shadow(color: Color(hex: "2D8C82").opacity(0.35), radius: 18, x: 0, y: 10)

                        Text("KAYA Health")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(Color(hex: "101828"))

                        Text("Entra com a tua conta para ver o painel de saúde.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "5D6B82"))
                            .multilineTextAlignment(.center)
                    }

                    // Form card
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
                            .styledInput()

                        Text("Palavra-passe")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "475467"))
                        SecureField("••••••••", text: $password)
                            .focused($focus, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { loginAction() }
                            .styledInput()

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

                    // Login button
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
                    .fullScreenCover(isPresented: $showDashboard) {
                        PatientDashboardView()
                    }
                    .onChange(of: auth.isLoggedIn) { loggedIn in
                        if loggedIn { showDashboard = true }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    private var canSubmit: Bool { !email.isEmpty && password.count >= 4 }

    private func loginAction() {
        focus = nil
        guard canSubmit else { return }
        Task { await auth.login(email: email, password: password) }
    }
}

// MARK: - Input Styling
private extension View {
    func styledInput() -> some View {
        self
            .padding(14)
            .background(Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "D0D5DD"), lineWidth: 1))
    }
}
