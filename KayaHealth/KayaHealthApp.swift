import SwiftUI

// MARK: - Config
// All backend/web URLs used throughout the app.
enum KayaConfig {
    static let homeURL               = URL(string: "https://genovesi-jm.github.io/health-/")!
    static let loginURL              = URL(string: "https://genovesi-jm.github.io/health-/login")!
    static let registerURL           = URL(string: "https://genovesi-jm.github.io/health-/register")!
    static let patientProfileURL     = URL(string: "https://genovesi-jm.github.io/health-/patient/profile")!
    static let dashboardURL          = URL(string: "https://genovesi-jm.github.io/health-/dashboard")!
    static let servicesURL           = URL(string: "https://genovesi-jm.github.io/health-/services")!
    static let specialistsURL        = URL(string: "https://genovesi-jm.github.io/health-/medicos")!
    static let prescriptionRequestURL = URL(string: "https://genovesi-jm.github.io/health-/prescricoes/pedido")!
}

// MARK: - Root View
// Used by the Xcode entry point (KayaApp.swift):
//   @main struct KayaApp: App {
//       var body: some Scene { WindowGroup { KayaRootView() } }
//   }
struct KayaRootView: View {
    var body: some View {
        NavigationStack {
            KayaHomeView()
        }
    }
}
