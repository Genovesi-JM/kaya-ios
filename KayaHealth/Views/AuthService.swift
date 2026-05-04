import Foundation
import Security

// MARK: - Auth Models
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let access_token: String
    let token_type: String
}

struct UserProfile: Decodable {
    let id: Int?
    let email: String?
    let full_name: String?
    let role: String?
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:   return "Email ou palavra-passe incorrectos."
        case .networkError(let m):  return "Erro de rede: \(m)"
        case .decodingError:        return "Resposta inesperada do servidor."
        }
    }
}

// MARK: - Auth Service
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isLoggedIn = false
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "https://health.geovisionops.com"
    private let keychainKey = "kaya_jwt_token"

    private init() {
        // Restore session from keychain on launch
        if let token = loadToken(), !token.isEmpty {
            isLoggedIn = true
            Task { await fetchProfile(token: token) }
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/api/auth/login") else { return }

        // Backend expects JSON { email, password }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(LoginRequest(email: email, password: password))

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                errorMessage = AuthError.networkError("sem resposta HTTP").errorDescription
                return
            }
            if http.statusCode == 401 || http.statusCode == 400 {
                errorMessage = AuthError.invalidCredentials.errorDescription
                return
            }
            guard http.statusCode == 200 else {
                errorMessage = AuthError.networkError("código \(http.statusCode)").errorDescription
                return
            }
            let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
            saveToken(decoded.access_token)
            isLoggedIn = true
            await fetchProfile(token: decoded.access_token)
        } catch {
            errorMessage = AuthError.networkError(error.localizedDescription).errorDescription
        }
    }

    // MARK: - Profile
    func fetchProfile(token: String) async {
        guard let url = URL(string: "\(baseURL)/me") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) else { return }
        profile = decoded
    }

    // MARK: - Logout
    func logout() {
        deleteToken()
        isLoggedIn = false
        profile = nil
    }

    // MARK: - Token getter (for WebView injection)
    func token() -> String? { loadToken() }

    // MARK: - Keychain
    private func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: keychainKey,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      keychainKey,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteToken() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: keychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}


