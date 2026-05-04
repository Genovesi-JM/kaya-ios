import SwiftUI

// MARK: - Login Screen (entry point → PatientDashboardView)
struct KayaLoginView: View {
    @StateObject private var auth = AuthService.shared

    var body: some View {
        Group {
            if auth.isLoggedIn {
                PatientDashboardView()
            } else {
                NativeLoginForm()
                    .navigationTitle("Entrar na KAYA")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
