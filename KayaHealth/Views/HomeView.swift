import SwiftUI

// MARK: - Home View
struct KayaHomeView: View {
    @State private var showMenu = false
    @State private var webDestination: WebDestination?

    var body: some View {
        ZStack {
            Color(hex: "F7FAFC").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    hero
                    quickActions
                    services
                    howItWorks
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .sheet(item: $webDestination) { destination in
            KayaWebViewScreen(destination: destination)
        }
        .fullScreenCover(isPresented: $showMenu) {
            KayaMenuView(
                openPortal:         { open(.portal)        },
                openRegister:       { open(.register)      },
                openServices:       { open(.services)      },
                openSpecialists:    { open(.specialists)   },
                openPrescriptions:  { open(.prescriptions) },
                openPatientProfile: { open(.patientProfile)},
                openDashboard:      { open(.dashboard)     }
            )
            .background(Color.clear)
        }
        .navigationBarHidden(true)
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color(hex: "2D8C82"), Color(hex: "55B7A8")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("KAYA")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "101828"))
                Text("Saúde na sua mão")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "2D8C82"))
            }

            Spacer()

            Button { showMenu = true } label: {
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2).frame(width: 22, height: 2)
                    RoundedRectangle(cornerRadius: 2).frame(width: 16, height: 2)
                    RoundedRectangle(cornerRadius: 2).frame(width: 22, height: 2)
                }
                .foregroundStyle(Color(hex: "101828"))
                .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Menu")
        }
        .padding(.top, 12)
    }

    // MARK: Hero
    private var hero: some View {
        VStack(spacing: 16) {
            Text("A tua saúde,\nmais simples.")
                .font(.system(size: 34, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "101828"))
                .padding(.top, 8)

            Text("Marca consultas, pede receitas e acompanha a tua saúde num só portal.")
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "5D6B82"))
                .lineSpacing(3)

            VStack(spacing: 10) {
                // Dashboard directo — principal CTA
                Button { open(.dashboard) } label: {
                    Label("Ver painel do paciente", systemImage: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color(hex: "2D8C82"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
                }

                NavigationLink { KayaLoginView() } label: {
                    Label("Entrar no portal", systemImage: "arrow.right.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.white)
                        .foregroundStyle(Color(hex: "2D8C82"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "C8E9E4"), lineWidth: 1.5))
                }

                Button { open(.register) } label: {
                    Text("Criar conta grátis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "2D8C82"))
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 12)
    }

    // MARK: Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acesso rápido")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "101828"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionCard(title: "Painel",       icon: "gauge.with.dots.needle.bottom.50percent", color: "2D8C82") { open(.dashboard)      }
                QuickActionCard(title: "Teleconsulta", icon: "video.fill",                              color: "3B82F6") { open(.services)       }
                QuickActionCard(title: "Receitas",     icon: "pills.fill",                              color: "8B5CF6") { open(.prescriptions)  }
                QuickActionCard(title: "Perfil",       icon: "person.text.rectangle.fill",              color: "EF7C8E") { open(.patientProfile) }
            }
        }
    }

    // MARK: Services
    private var services: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("O que podes fazer")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "101828"))

            VStack(spacing: 10) {
                ServiceRow(icon: "calendar",          title: "Marcar consulta",           description: "Escolhe especialidade, médico e horário.")
                ServiceRow(icon: "video",             title: "Fazer teleconsulta",         description: "Fala com um médico sem sair de casa.")
                ServiceRow(icon: "pills",             title: "Pedir renovação de receita", description: "Envia o pedido ao médico online.")
                ServiceRow(icon: "heart.text.square", title: "Saúde crónica",              description: "Medicação, sinais vitais e follow-ups.")
            }
        }
    }

    // MARK: How It Works
    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Como funciona")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "101828"))

            VStack(spacing: 10) {
                StepRow(number: "1", title: "Cria a tua conta")
                StepRow(number: "2", title: "Escolhe o serviço")
                StepRow(number: "3", title: "Acompanha no painel")
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
        }
    }

    // MARK: Helper
    private func open(_ kind: WebDestination.Kind) {
        showMenu = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            webDestination = WebDestination(kind: kind)
        }
    }
}
