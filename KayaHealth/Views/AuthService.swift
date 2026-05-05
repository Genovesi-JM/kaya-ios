import Foundation
import Security

// MARK: - API Helper
enum API {
    static let base = "https://health.geovisionops.com"

    static func request(_ path: String, method: String = "GET", token: String? = nil, body: [String: Any]? = nil) -> URLRequest {
        var req = URLRequest(url: URL(string: "\(base)\(path)")!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        if let b = body { req.httpBody = try? JSONSerialization.data(withJSONObject: b) }
        return req
    }
}

// MARK: - Auth Models
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:   return "Email ou palavra-passe incorretos."
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
    @Published var profile: PatientProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let keychainKey = "kaya_jwt_token"

    private init() {
        if let t = loadToken(), !t.isEmpty {
            isLoggedIn = true
            Task { await loadProfile() }
        }
    }

    var token: String? { loadToken() }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let req = API.request("/api/v1/auth/login", method: "POST",
                              body: ["username": email, "password": password])
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
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
            let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
            saveToken(decoded.access_token)
            isLoggedIn = true
            await loadProfile()
        } catch {
            errorMessage = AuthError.networkError(error.localizedDescription).errorDescription
        }
    }

    func loadProfile() async {
        guard let t = loadToken() else { return }
        guard let (data, _) = try? await URLSession.shared.data(for: API.request("/api/v1/patients/me", token: t)),
              let decoded = try? JSONDecoder().decode(PatientProfile.self, from: data) else { return }
        profile = decoded
    }

    func logout() {
        deleteToken()
        isLoggedIn = false
        profile = nil
    }

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

    func loadToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: keychainKey,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
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
