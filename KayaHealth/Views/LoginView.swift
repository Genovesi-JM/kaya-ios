import SwiftUI

// MARK: - Login Screen (único ecrã antes do painel)
struct LoginScreen: View {
    @StateObject private var auth = AuthService.shared
    @State private var email    = ""
    @State private var password = ""
    @FocusState private var focus: Field?
    enum Field { case email, password }

    var body: some View {
        ZStack {
            // Fundo gradiente suave
            LinearGradient(
                colors: [Color(hex: "EAF7F4"), Color(hex: "F7FAFC")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 50)

                    // Logo
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient(
                                colors: [Color(hex: "2D8C82"), Color(hex: "55B7A8")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 84, height: 84)
                            .overlay(
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .shadow(color: Color(hex: "2D8C82").opacity(0.4), radius: 20, x: 0, y: 10)

                        Text("KAYA Health")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(Color(hex: "101828"))

                        Text("A tua saúde, num só lugar.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(hex: "5D6B82"))
                    }

                    // Form
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
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
                                .fieldStyle()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Palavra-passe")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: "475467"))
                            SecureField("••••••••", text: $password)
                                .focused($focus, equals: .password)
                                .submitLabel(.go)
                                .onSubmit { doLogin() }
                                .fieldStyle()
                        }

                        if let err = auth.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(err)
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "EF4444"))
                            .padding(12)
                            .background(Color(hex: "EF4444").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)

                    // CTA Entrar
                    Button { doLogin() } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Text("Entrar")
                                        .font(.system(size: 17, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(canSubmit ? Color(hex: "2D8C82") : Color(hex: "A0C8C2"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color(hex: "2D8C82").opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .disabled(!canSubmit || auth.isLoading)

                    // Criar conta
                    Button {
                        UIApplication.shared.open(KayaConfig.registerURL)
                    } label: {
                        Text("Não tens conta? ")
                            .foregroundStyle(Color(hex: "667085"))
                        + Text("Cria uma grátis")
                            .foregroundStyle(Color(hex: "2D8C82"))
                            .bold()
                    }
                    .font(.system(size: 14))

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var canSubmit: Bool { !email.isEmpty && password.count >= 4 }

    private func doLogin() {
        focus = nil
        guard canSubmit else { return }
        Task { await auth.login(email: email, password: password) }
    }
}

// MARK: - Field Style
private extension View {
    func fieldStyle() -> some View {
        self
            .padding(15)
            .background(Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "D0D5DD"), lineWidth: 1))
    }
}
