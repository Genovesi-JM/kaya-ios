import SwiftUI

// MARK: - Burger Drawer (lateral, não sheet)
struct KayaMenuView: View {
    @Environment(\.dismiss) private var dismiss

    let openPortal:         () -> Void
    let openRegister:       () -> Void
    let openServices:       () -> Void
    let openSpecialists:    () -> Void
    let openPrescriptions:  () -> Void
    let openPatientProfile: () -> Void
    let openDashboard:      () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            // Fundo escuro
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Drawer lateral
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("KAYA")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundStyle(Color(hex: "101828"))
                            Text("Portal do Paciente")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "2D8C82"))
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "667085"))
                                .frame(width: 36, height: 36)
                                .background(Color(hex: "F2F4F7"))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 56)
                    .padding(.bottom, 24)

                    Divider().padding(.horizontal, 20)

                    // Menu items
                    ScrollView {
                        VStack(spacing: 2) {
                            MenuRow(icon: "house.fill",                 title: "Início",              color: "2D8C82") { dismiss() }
                            MenuRow(icon: "gauge.with.dots.needle.bottom.50percent", title: "Painel do paciente", color: "3B82F6") { openDashboard() }
                            MenuRow(icon: "heart.text.square.fill",     title: "Serviços",            color: "059669") { openServices() }
                            MenuRow(icon: "person.text.rectangle.fill", title: "Perfil",              color: "8B5CF6") { openPatientProfile() }
                            MenuRow(icon: "stethoscope",                title: "Especialistas",       color: "EF4444") { openSpecialists() }
                            MenuRow(icon: "pills.fill",                 title: "Receitas",            color: "F59E0B") { openPrescriptions() }
                            MenuRow(icon: "questionmark.circle.fill",   title: "Ajuda / FAQ",         color: "64748B") { openPortal() }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                    }

                    Spacer()

                    // CTAs
                    VStack(spacing: 8) {
                        Button(action: openDashboard) {
                            HStack {
                                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                Text("Ver painel do paciente")
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "2D8C82"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button(action: openPortal) {
                            Text("Entrar / Login")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white)
                                .foregroundStyle(Color(hex: "2D8C82"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "C8E9E4"), lineWidth: 1.5))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
                .frame(width: UIScreen.main.bounds.width * 0.80)
                .background(.white)
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Menu Row
struct MenuRow: View {
    let icon: String
    let title: String
    let color: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: color))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: color).opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "101828"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "CBD5E1"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
