import SwiftUI

// MARK: - Entry Point
@main
struct KayaHealthApp: App {
    @StateObject private var auth = AuthService.shared

    var body: some Scene {
        WindowGroup {
            KayaRootView()
                .environmentObject(auth)
        }
    }
}

// MARK: - URLs do backend
enum KayaConfig {
    static let baseAPI               = "https://health.geovisionops.com"
    static let registerURL           = URL(string: "https://genovesi-jm.github.io/health-/register")!
    static let servicesURL           = URL(string: "https://genovesi-jm.github.io/health-/services")!
    static let specialistsURL        = URL(string: "https://genovesi-jm.github.io/health-/medicos")!
    static let prescriptionURL       = URL(string: "https://genovesi-jm.github.io/health-/prescricoes/pedido")!
    static let teleconsultaURL       = URL(string: "https://genovesi-jm.github.io/health-/teleconsulta")!
}

// MARK: - Root: Login ou Dashboard
struct KayaRootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        if auth.isLoggedIn {
            MainDashboardView()
        } else {
            LoginScreen()
        }
    }
}
