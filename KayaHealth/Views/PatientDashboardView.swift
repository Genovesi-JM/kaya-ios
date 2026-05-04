import SwiftUI

// MARK: - Dashboard Principal
struct MainDashboardView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm   = DashboardViewModel()
    @State private var showProfile     = false
    @State private var showTriagem     = false
    @State private var showTeleconsult = false
    @State private var showReceitas    = false
    @State private var showEspecialis  = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "F5F7FA").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    heroSection
                    acessoRapidoSection
                    oPodeFazerSection
                    comoFuncionaSection
                    if !vm.readings.isEmpty    { readingsSection }
                    if !vm.medications.isEmpty { medsSection }
                    notifSection
                    Spacer(minLength: 32)
                }
            }
            .refreshable { await vm.load(token: auth.token() ?? "") }

            topBar
        }
        .sheet(isPresented: $showProfile)     { ProfileView() }
        .sheet(isPresented: $showTriagem)     { TriagemView() }
        .sheet(isPresented: $showTeleconsult) { TeleconsultaView() }
        .sheet(isPresented: $showReceitas)    { ReceitasView() }
        .sheet(isPresented: $showEspecialis)  { EspecialistasView() }
        .task { await vm.load(token: auth.token() ?? "") }
    }

    // MARK: - TopBar
    private var topBar: some View {
        HStack {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "2D8C82"))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("KAYA").font(.system(size: 17, weight: .heavy)).foregroundStyle(Color(hex: "101828"))
                    Text("Saúde na sua mão").font(.system(size: 10)).foregroundStyle(Color(hex: "667085"))
                }
            }
            .padding(.leading, 16)

            Spacer()

            Button { auth.logout() } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "667085"))
                    .padding(8)
            }
            .padding(.trailing, 8)

            Button { showProfile = true } label: {
                Circle()
                    .fill(Color(hex: "2D8C82").opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(initials).font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: "2D8C82"))
                    )
            }
            .padding(.trailing, 16)
        }
        .frame(height: 56)
        .background(.ultraThinMaterial)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private var initials: String {
        String(auth.profile?.full_name?.prefix(1) ?? auth.profile?.email?.prefix(1) ?? "?").uppercased()
    }
    private var firstName: String {
        (auth.profile?.full_name ?? "").components(separatedBy: " ").first ?? "Paciente"
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("A tua saúde,\nnum só lugar.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: "101828"))
                    .lineSpacing(2)
                Text("Olá, \(firstName) — o teu painel está pronto.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "667085"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Acesso Rápido (2x2 grid com "Abrir →")
    private var acessoRapidoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Acesso rápido")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "667085"))
                .padding(.horizontal, 20)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                AbrirCard(title: "Triagem",      subtitle: "Avalia os teus sintomas",  icon: "waveform.path.ecg", color: "2D8C82") { showTriagem     = true }
                AbrirCard(title: "Teleconsulta", subtitle: "Consulta por vídeo",        icon: "video.fill",        color: "3B82F6") { showTeleconsult = true }
                AbrirCard(title: "Receitas",     subtitle: "As tuas prescrições",       icon: "pills.fill",        color: "8B5CF6") { showReceitas    = true }
                AbrirCard(title: "Perfil",       subtitle: "A tua conta",               icon: "person.fill",       color: "EF7C8E") { showProfile     = true }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - O que podes fazer
    private var oPodeFazerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("O que podes fazer")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "667085"))

            VStack(spacing: 0) {
                FazerRow(icon: "calendar.badge.plus",   color: "2D8C82", title: "Marcar consulta",           subtitle: "Escolhe especialidade, médico e horário.") { showEspecialis = true }
                Divider().padding(.leading, 62)
                FazerRow(icon: "video.fill",             color: "3B82F6", title: "Fazer teleconsulta",         subtitle: "Fala com um médico sem sair de casa.")     { showTeleconsult = true }
                Divider().padding(.leading, 62)
                FazerRow(icon: "arrow.clockwise.circle", color: "8B5CF6", title: "Pedir renovação de receita", subtitle: "Envia o pedido ao médico online.")          { showReceitas = true }
                Divider().padding(.leading, 62)
                FazerRow(icon: "heart.text.square.fill", color: "2D8C82", title: "Saúde crónica",              subtitle: "Medicação, sinais vitais e follow-ups.")    { showTriagem = true }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    // MARK: - Como funciona
    private var comoFuncionaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Como funciona")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "667085"))

            VStack(spacing: 16) {
                StepRow(number: "1", title: "Inicia sessão na tua conta")
                StepRow(number: "2", title: "Escolhe o serviço que precisas")
                StepRow(number: "3", title: "Acompanha tudo no painel")
            }
            .padding(18)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Medições
    private var readingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Minhas Medições", icon: "waveform.path.ecg", color: "2D8C82")
            VStack(spacing: 10) { ForEach(vm.readings.prefix(4)) { ReadingRow(reading: $0) } }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    // MARK: - Medicação
    private var medsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Medicação", icon: "pills.fill", color: "8B5CF6")
            VStack(spacing: 10) { ForEach(vm.medications.prefix(4)) { MedicationRow(med: $0) } }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    // MARK: - Notificações
    private var notifSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Notificações", icon: "bell.fill", color: "F59E0B")
            if vm.isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(20).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
            } else if vm.notifications.isEmpty {
                InfoRow(icon: "bell.slash", color: "A0AEC0", text: "Sem notificações de momento.")
            } else {
                VStack(spacing: 10) { ForEach(vm.notifications.prefix(5)) { NotificationRow(notif: $0) } }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
}

// MARK: - AbrirCard (2×2 estilo web, mas nativo)
private struct AbrirCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: color).opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: color))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "101828"))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "667085"))
                        .lineLimit(2)
                }
                HStack(spacing: 4) {
                    Text("Abrir")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: color))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: color))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FazerRow
private struct FazerRow: View {
    let icon: String
    let color: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: color).opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: color))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(Color(hex: "667085"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "C0CCDA"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - SectionLabel
private struct SectionLabel: View {
    let title: String; let icon: String; let color: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: color))
            Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: "101828"))
        }
    }
}

// MARK: - InfoRow (empty state)
private struct InfoRow: View {
    let icon: String; let color: String; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Color(hex: color))
            Text(text).font(.system(size: 14)).foregroundStyle(Color(hex: "667085"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Profile Sheet
struct ProfileView: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Conta") {
                    LabeledContent("Email", value: auth.profile?.email ?? "—")
                    LabeledContent("Nome", value: auth.profile?.full_name ?? "—")
                    LabeledContent("Tipo", value: auth.profile?.role?.capitalized ?? "—")
                }
                Section {
                    Button(role: .destructive) { auth.logout(); dismiss() } label: {
                        Label("Terminar sessão", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
        }
    }
}

// MARK: - Ecrãs Nativos de Serviços

struct TriagemView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ServiceHero(icon: "waveform.path.ecg", color: "2D8C82", title: "Triagem", subtitle: "Descreve os teus sintomas e recebe orientação médica rápida.")
                    ComingSoonCard(message: "Triagem de sintomas em desenvolvimento. Em breve poderás descrever os teus sintomas e receber orientação.")
                }
                .padding(20)
            }
            .background(Color(hex: "F5F7FA").ignoresSafeArea())
            .navigationTitle("Triagem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
        }
    }
}

struct TeleconsultaView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ServiceHero(icon: "video.fill", color: "3B82F6", title: "Teleconsulta", subtitle: "Consultas médicas por videochamada, sem sair de casa.")
                    ComingSoonCard(message: "Videoconsultas em desenvolvimento. Em breve poderás agendar e entrar numa consulta directamente aqui.")
                }
                .padding(20)
            }
            .background(Color(hex: "F5F7FA").ignoresSafeArea())
            .navigationTitle("Teleconsulta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
        }
    }
}

struct ReceitasView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm = ReceitasViewModel()
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ServiceHero(icon: "pills.fill", color: "8B5CF6", title: "Receitas Médicas", subtitle: "As tuas receitas e pedidos de medicação.")
                    if vm.isLoading { ProgressView().padding(.top, 40) }
                    else if vm.items.isEmpty { ComingSoonCard(message: "Ainda não tens receitas associadas à tua conta.") }
                    else { VStack(spacing: 12) { ForEach(vm.items) { ReceitaRow(item: $0) } } }
                }
                .padding(20)
            }
            .background(Color(hex: "F5F7FA").ignoresSafeArea())
            .navigationTitle("Receitas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
            .task { await vm.load(token: auth.token() ?? "") }
        }
    }
}

struct EspecialistasView: View {
    @StateObject private var vm = EspecialistasViewModel()
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ServiceHero(icon: "stethoscope", color: "EF7C8E", title: "Especialistas", subtitle: "Encontra médicos especialistas disponíveis.")
                    if vm.isLoading { ProgressView().padding(.top, 40) }
                    else if vm.doctors.isEmpty { ComingSoonCard(message: "Nenhum especialista disponível de momento.") }
                    else { VStack(spacing: 12) { ForEach(vm.doctors) { DoctorRow(doc: $0) } } }
                }
                .padding(20)
            }
            .background(Color(hex: "F5F7FA").ignoresSafeArea())
            .navigationTitle("Especialistas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
            .task { await vm.load(token: auth.token() ?? "") }
        }
    }
}

// MARK: - Receitas ViewModel
@MainActor final class ReceitasViewModel: ObservableObject {
    @Published var items: [PrescriptionItem] = []
    @Published var isLoading = false
    func load(token: String) async {
        isLoading = true; defer { isLoading = false }
        guard let url = URL(string: "\(KayaConfig.baseAPI)/api/v1/prescriptions/me"), !token.isEmpty else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode([PrescriptionItem].self, from: data) else { return }
        items = decoded
    }
}
struct PrescriptionItem: Identifiable, Decodable { let id: String; let medication_name: String?; let status: String?; let created_at: String? }

// MARK: - Especialistas ViewModel
@MainActor final class EspecialistasViewModel: ObservableObject {
    @Published var doctors: [DoctorItem] = []
    @Published var isLoading = false
    func load(token: String) async {
        isLoading = true; defer { isLoading = false }
        guard let url = URL(string: "\(KayaConfig.baseAPI)/api/v1/doctors"), !token.isEmpty else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode([DoctorItem].self, from: data) else { return }
        doctors = decoded
    }
}
struct DoctorItem: Identifiable, Decodable { let id: String; let full_name: String?; let specialty: String?; let is_available: Bool? }

// MARK: - Service Sub-views
private struct ServiceHero: View {
    let icon: String; let color: String; let title: String; let subtitle: String
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Color(hex: color).opacity(0.12)).frame(width: 80, height: 80)
                Image(systemName: icon).font(.system(size: 34, weight: .semibold)).foregroundStyle(Color(hex: color))
            }
            Text(title).font(.system(size: 22, weight: .bold)).foregroundStyle(Color(hex: "101828"))
            Text(subtitle).font(.system(size: 14)).foregroundStyle(Color(hex: "667085")).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(24).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private struct ComingSoonCard: View {
    let message: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.badge.fill").font(.system(size: 24)).foregroundStyle(Color(hex: "F59E0B"))
            VStack(alignment: .leading, spacing: 4) {
                Text("Em breve").font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: "101828"))
                Text(message).font(.system(size: 13)).foregroundStyle(Color(hex: "667085")).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct ReceitaRow: View {
    let item: PrescriptionItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(Color(hex: "8B5CF6").opacity(0.12)).frame(width: 42, height: 42); Image(systemName: "pills.fill").font(.system(size: 18)).foregroundStyle(Color(hex: "8B5CF6")) }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.medication_name ?? "Receita").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                if let s = item.status { Text(s.capitalized).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
            }
            Spacer()
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct DoctorRow: View {
    let doc: DoctorItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(Color(hex: "EF7C8E").opacity(0.12)).frame(width: 42, height: 42); Image(systemName: "stethoscope").font(.system(size: 18)).foregroundStyle(Color(hex: "EF7C8E")) }
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.full_name ?? "Médico").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                if let s = doc.specialty { Text(s).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
            }
            Spacer()
            if doc.is_available == true {
                Text("Disponível").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: "2D8C82"))
                    .padding(.horizontal, 10).padding(.vertical, 4).background(Color(hex: "2D8C82").opacity(0.1)).clipShape(Capsule())
            }
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Dashboard ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var readings:      [DeviceReadingItem] = []
    @Published var medications:   [MedicationItem]    = []
    @Published var notifications: [NotifItem]         = []
    @Published var isLoading = false

    private let base = KayaConfig.baseAPI

    func load(token: String) async {
        isLoading = true; defer { isLoading = false }
        async let r: Void = fetchReadings(token: token)
        async let m: Void = fetchMeds(token: token)
        async let n: Void = fetchNotifs(token: token)
        _ = await (r, m, n)
    }

    private func get<T: Decodable>(_ path: String, token: String, as: T.Type) async -> T? {
        guard let url = URL(string: "\(base)\(path)") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func fetchReadings(token: String) async {
        if let r = await get("/api/v1/readings/me", token: token, as: ReadingsResponse.self) { readings = r.readings }
    }
    private func fetchMeds(token: String) async {
        if let m = await get("/api/v1/medications/me", token: token, as: [MedicationItem].self) { medications = m }
    }
    private func fetchNotifs(token: String) async {
        if let n = await get("/api/v1/notifications/me", token: token, as: [NotifItem].self) { notifications = n }
    }
}

// MARK: - Models
struct ReadingsResponse: Decodable { let readings: [DeviceReadingItem]; let total: Int? }
struct DeviceReadingItem: Identifiable, Decodable { let id: String; let reading_type: String; let value: Double; let unit: String?; let measured_at: String? }
struct MedicationItem: Identifiable, Decodable { let id: String; let medication_name: String; let dosage: String?; let frequency: String?; let is_active: Bool? }
struct NotifItem: Identifiable, Decodable { let id: String; let title: String?; let message: String?; let is_read: Bool? }

// MARK: - ReadingRow
private struct ReadingRow: View {
    let reading: DeviceReadingItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(readingColor.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: readingIcon).font(.system(size: 18, weight: .semibold)).foregroundStyle(readingColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(readingLabel).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                if let d = reading.measured_at { Text(fmt(d)).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
            }
            Spacer()
            Text(valueText)
                .font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: "101828"))
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    private var valueText: String {
        let fmt = reading.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"
        return String(format: fmt, reading.value) + " " + (reading.unit ?? "")
    }
    private var readingIcon: String {
        switch reading.reading_type.lowercased() {
        case "blood_pressure": return "heart.fill"
        case "glucose":        return "drop.fill"
        case "temperature":    return "thermometer"
        case "weight":         return "scalemass.fill"
        default:               return "waveform.path.ecg"
        }
    }
    private var readingColor: Color {
        switch reading.reading_type.lowercased() {
        case "blood_pressure": return Color(hex: "EF4444")
        case "glucose":        return Color(hex: "F59E0B")
        case "temperature":    return Color(hex: "3B82F6")
        case "weight":         return Color(hex: "8B5CF6")
        default:               return Color(hex: "2D8C82")
        }
    }
    private var readingLabel: String {
        switch reading.reading_type.lowercased() {
        case "blood_pressure": return "Pressão Arterial"
        case "glucose":        return "Glicose"
        case "temperature":    return "Temperatura"
        case "weight":         return "Peso"
        case "heart_rate":     return "Freq. Cardíaca"
        default:               return reading.reading_type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    private func fmt(_ s: String) -> String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let d = f.date(from: s) else { return s }
        let o = DateFormatter(); o.dateFormat = "dd MMM, HH:mm"; o.locale = Locale(identifier: "pt_PT")
        return o.string(from: d)
    }
}

// MARK: - MedicationRow
private struct MedicationRow: View {
    let med: MedicationItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "8B5CF6").opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: "pills.fill").font(.system(size: 18)).foregroundStyle(Color(hex: "8B5CF6"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(med.medication_name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                if let d = med.dosage { Text(dosageText(d: d, freq: med.frequency)).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
            }
            Spacer()
            if med.is_active == true {
                Text("Activo").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: "2D8C82"))
                    .padding(.horizontal, 10).padding(.vertical, 4).background(Color(hex: "2D8C82").opacity(0.1)).clipShape(Capsule())
            }
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    private func dosageText(d: String, freq: String?) -> String {
        if let f = freq { return d + " · " + f } else { return d }
    }
}

// MARK: - NotificationRow
private struct NotificationRow: View {
    let notif: NotifItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "F59E0B").opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: notif.is_read == true ? "bell" : "bell.badge.fill").font(.system(size: 18)).foregroundStyle(Color(hex: "F59E0B"))
            }
            VStack(alignment: .leading, spacing: 2) {
                if let t = notif.title { Text(t).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828")) }
                if let m = notif.message { Text(m).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")).lineLimit(2) }
            }
            Spacer()
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
