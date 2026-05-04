import SwiftUI
import WebKit

// MARK: - Main App
// NOTE: Remove the @main from this file if your Xcode project already has
// a KayaApp.swift entry point. Keep only ONE @main in the whole target.
// If starting fresh, rename your Xcode-generated app struct to KayaApp
// and replace ContentView() with KayaRootView().
//
// Quick fix in Xcode's KayaApp.swift:
//
//   @main
//   struct KayaApp: App {
//       var body: some Scene {
//           WindowGroup { KayaRootView() }
//       }
//   }
//
// Then delete ContentView.swift and add all files from this folder to the target.

// MARK: - Config
enum KayaConfig {
    static let homeURL              = URL(string: "https://genovesi-jm.github.io/health-/")!
    static let loginURL             = URL(string: "https://genovesi-jm.github.io/health-/login")!
    static let registerURL          = URL(string: "https://genovesi-jm.github.io/health-/register")!
    static let patientProfileURL    = URL(string: "https://genovesi-jm.github.io/health-/patient/profile")!
    static let dashboardURL         = URL(string: "https://genovesi-jm.github.io/health-/dashboard")!
    static let servicesURL          = URL(string: "https://genovesi-jm.github.io/health-/services")!
    static let specialistsURL       = URL(string: "https://genovesi-jm.github.io/health-/medicos")!
    static let prescriptionRequestURL = URL(string: "https://genovesi-jm.github.io/health-/prescricoes/pedido")!
}

// MARK: - Root
struct KayaRootView: View {
    var body: some View {
        NavigationStack {
            KayaHomeView()
        }
    }
}

// MARK: - Config
enum KayaConfig {
    // Change these URLs if your deployed routes are different.
    static let homeURL         = URL(string: "https://genovesi-jm.github.io/health-/")!
    static let loginURL        = URL(string: "https://genovesi-jm.github.io/health-/login")!
    static let registerURL     = URL(string: "https://genovesi-jm.github.io/health-/register")!
    static let patientProfileURL = URL(string: "https://genovesi-jm.github.io/health-/patient/profile")!
    static let dashboardURL    = URL(string: "https://genovesi-jm.github.io/health-/dashboard")!
    static let servicesURL     = URL(string: "https://genovesi-jm.github.io/health-/services")!
    static let specialistsURL  = URL(string: "https://genovesi-jm.github.io/health-/medicos")!
    static let prescriptionRequestURL = URL(string: "https://genovesi-jm.github.io/health-/prescricoes/pedido")!
}

// MARK: - Root
struct KayaRootView: View {
    var body: some View {
        NavigationStack {
            KayaHomeView()
        }
    }
}
