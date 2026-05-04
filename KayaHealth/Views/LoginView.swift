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
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
