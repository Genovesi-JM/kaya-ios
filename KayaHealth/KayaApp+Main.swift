import SwiftUI

// MARK: - Entry Point
// This is the ONLY @main in the project.
// In Xcode: delete the auto-generated ContentView.swift,
// then make sure this file is added to your app target.
@main
struct KayaApp: App {
    var body: some Scene {
        WindowGroup {
            KayaRootView()
        }
    }
}
