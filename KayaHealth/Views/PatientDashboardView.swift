import SwiftUI
import WebKit

// MARK: - Patient Dashboard with Auth Session
struct PatientDashboardView: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if auth.isLoggedIn {
                authenticatedDashboard
            } else {
                loginPrompt
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: Authenticated WebView with JWT injected
    private var authenticatedDashboard: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "101828"))
                        .frame(width: 38, height: 38)
                        .background(Color(hex: "F2F4F7"))
                        .clipShape(Circle())
                }

                Spacer()

                VStack(spacing: 1) {
                    Text("Painel do Paciente")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "101828"))
                    if let name = auth.profile?.full_name {
                        Text(name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "2D8C82"))
                    }
                }

                Spacer()

                Button { auth.logout() } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "EF4444"))
                        .frame(width: 38, height: 38)
                        .background(Color(hex: "FEF2F2"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)

            // WebView with JWT injected
            AuthenticatedWebView(
                url: KayaConfig.dashboardURL,
                token: auth.token() ?? ""
            )
        }
        .background(Color(hex: "F7FAFC"))
    }

    // MARK: Login Prompt
    private var loginPrompt: some View {
        NativeLoginForm()
    }
}

// MARK: - WKWebView with Authorization header + cookie
struct AuthenticatedWebView: UIViewRepresentable {
    let url: URL
    let token: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Inject JWT as localStorage + cookie via JS
        let js = """
        localStorage.setItem('access_token', '\(token)');
        document.cookie = 'access_token=\(token); path=/; SameSite=Lax';
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor(Color(hex: "F7FAFC"))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

// MARK: - Native Login Form (with real auth)
struct NativeLoginForm: View {
    @StateObject private var auth = AuthService.shared
    @State private var email    = ""
    @State private var password = ""
    @FocusState private var focus: Field?

    enum Field { case email, password }

    var body: some View {
        ZStack {
            Color(hex: "F7FAFC").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 30)

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
                        Group {
                            Text("Email").font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: "475467"))
                            TextField("email@exemplo.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focus, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focus = .password }
                                .styledInput()
                        }
                        Group {
                            Text("Palavra-passe").font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: "475467"))
                            SecureField("••••••••", text: $password)
                                .focused($focus, equals: .password)
                                .submitLabel(.go)
                                .onSubmit { loginAction() }
                                .styledInput()
                        }

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

                    Spacer(minLength: 20)
                }
                .padding(20)
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

// MARK: - Input Styling Modifier
private extension View {
    func styledInput() -> some View {
        self
            .padding(14)
            .background(Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "D0D5DD"), lineWidth: 1))
    }
}
