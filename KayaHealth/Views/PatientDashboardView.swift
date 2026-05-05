import SwiftUI

// MARK: - App Routes (push navigation)
enum AppRoute: Hashable {
    case profile, triagem, teleconsult, receitas, especialistas, consultas
    case selfCare, consents, family, settings, pricing
}

// MARK: - Dashboard Principal
struct MainDashboardView: View {
    @StateObject private var auth  = AuthService.shared
    @StateObject private var vm    = DashboardViewModel()
    @State private var path        = NavigationPath()
    @State private var showDrawer  = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                Color(hex: "F5F7FA").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 60)
                        heroSection
                        if let state = vm.patientState { patientStateCard(state) }
                        kpiStrip
                        acessoRapidoSection
                        if !vm.consultations.isEmpty  { consultasSection }
                        if !vm.readings.isEmpty       { readingsSection }
                        if !vm.medications.isEmpty    { medsSection }
                        notifSection
                        oPodeFazerSection
                        Spacer(minLength: 40)
                    }
                }
                .refreshable { await vm.loadAll(token: auth.token() ?? "") }

                topBar

                // Side Drawer overlay
                SideDrawerView(
                    isOpen: $showDrawer,
                    onProfile:       { path.append(AppRoute.profile) },
                    onTriagem:       { path.append(AppRoute.triagem) },
                    onConsultas:     { path.append(AppRoute.consultas) },
                    onSelfCare:      { path.append(AppRoute.selfCare) },
                    onConsents:      { path.append(AppRoute.consents) },
                    onReadings:      { path.append(AppRoute.teleconsult) },
                    onFamily:        { path.append(AppRoute.family) },
                    onNotifications: { },
                    onPricing:       { path.append(AppRoute.pricing) },
                    onSettings:      { path.append(AppRoute.settings) }
                )
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .profile:       ProfileView()
                case .triagem:       TriagemView()
                case .teleconsult:   TeleconsultaView()
                case .receitas:      ReceitasView()
                case .especialistas: EspecialistasView()
                case .consultas:     ConsultasView()
                case .selfCare:      SelfCareView()
                case .consents:      ConsentView()
                case .family:        FamilyView()
                case .settings:      SettingsView()
                case .pricing:       PricingView()
                }
            }
            .task { await vm.loadAll(token: auth.token() ?? "") }
        }
    }

    // MARK: - TopBar
    private var topBar: some View {
        HStack {
            // Burger menu button
            Button {
                withAnimation(.easeInOut(duration: 0.28)) { showDrawer.toggle() }
            } label: {
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "374151"))
                            .frame(width: 20, height: 2)
                    }
                }
                .padding(10)
            }
            .padding(.leading, 6)

            // Logo
            HStack(spacing: 8) {
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

            Spacer()

            // Bell
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "667085"))
                    .padding(8)
                if vm.unreadNotifCount > 0 {
                    Circle().fill(Color(hex: "EF4444")).frame(width: 8, height: 8).offset(x: 2, y: 2)
                }
            }
            .padding(.trailing, 4)

            // Avatar
            Button { path.append(AppRoute.profile) } label: {
                Circle()
                    .fill(Color(hex: "2D8C82").opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(Text(initials).font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: "2D8C82")))
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
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "2D8C82"))
            Text(firstName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: "101828"))
            Text(vm.isLoading ? "A carregar o teu painel…" : "O teu painel de saúde está atualizado.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "667085"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 18)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Bom dia 🌅" }
        if h < 18 { return "Boa tarde ☀️" }
        return "Boa noite 🌙"
    }

    // MARK: - Patient State Card (CTA inteligente)
    @ViewBuilder
    private func patientStateCard(_ state: PatientState) -> some View {
        let (bg, fg, icon) = stateStyle(urgency: state.next_action_urgency)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(fg)
                Text(state.state_label).font(.system(size: 14, weight: .bold)).foregroundStyle(fg)
                Spacer()
                if let d = state.next_action_deadline {
                    Text(d).font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3).background(fg.opacity(0.9)).clipShape(Capsule())
                }
            }
            if let complaint = state.last_triage_complaint {
                Text("Última queixa: \(complaint)")
                    .font(.system(size: 12)).foregroundStyle(fg.opacity(0.8)).lineLimit(2)
            }
            if let risk = state.last_triage_risk {
                HStack(spacing: 6) {
                    RiskBadge(risk: risk)
                    if let score = state.last_triage_score {
                        Text("Score: \(Int(score))").font(.system(size: 11, weight: .semibold)).foregroundStyle(fg.opacity(0.8))
                    }
                }
            }
            if state.next_action != "none" {
                Button {
                    switch state.next_action {
                    case "start_triage", "complete_triage": path.append(AppRoute.triagem)
                    case "book_consultation": path.append(AppRoute.especialistas)
                    default: break
                    }
                } label: {
                    HStack {
                        Text(state.next_action_label).font(.system(size: 14, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.right").font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(fg).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(18)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(fg.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func stateStyle(urgency: String) -> (Color, Color, String) {
        switch urgency {
        case "critical": return (Color(hex: "FEF2F2"), Color(hex: "DC2626"), "exclamationmark.triangle.fill")
        case "high":     return (Color(hex: "FFF7ED"), Color(hex: "EA580C"), "exclamationmark.circle.fill")
        case "medium":   return (Color(hex: "FFFBEB"), Color(hex: "D97706"), "clock.badge.exclamationmark")
        default:         return (Color(hex: "F0FDF4"), Color(hex: "16A34A"), "checkmark.circle.fill")
        }
    }

    // MARK: - KPI Strip
    private var kpiStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if let k = vm.kpis {
                    KPIChip(value: "\(k.total_consultations)", label: "Consultas",  icon: "stethoscope",          color: "3B82F6")
                    KPIChip(value: "\(k.total_triage_sessions)", label: "Triagens", icon: "waveform.path.ecg",    color: "2D8C82")
                    KPIChip(value: "\(k.total_doctors)",       label: "Médicos",    icon: "person.2.fill",        color: "8B5CF6")
                    KPIChip(value: "\(k.consultations_today)", label: "Hoje",       icon: "calendar",             color: "F59E0B")
                }
                if let s = vm.patientState {
                    KPIChip(value: "\(s.pending_consultations)",   label: "Pendentes",  icon: "clock.fill",             color: "EF4444")
                    KPIChip(value: "\(s.completed_consultations)", label: "Realizadas", icon: "checkmark.circle.fill",  color: "16A34A")
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 4)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Acesso Rápido
    private var acessoRapidoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Acesso Rápido", icon: "square.grid.2x2.fill", color: "101828")
                .padding(.horizontal, 16)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                AbrirCard(title: "Triagem",       subtitle: "Avalia os teus sintomas",   icon: "waveform.path.ecg",         color: "2D8C82") { path.append(AppRoute.triagem) }
                AbrirCard(title: "Teleconsulta",  subtitle: "Consulta por vídeo",         icon: "video.fill",                color: "3B82F6") { path.append(AppRoute.teleconsult) }
                AbrirCard(title: "Receitas",      subtitle: "As tuas prescrições",        icon: "pills.fill",                color: "8B5CF6") { path.append(AppRoute.receitas) }
                AbrirCard(title: "Especialistas", subtitle: "Encontra médicos",           icon: "stethoscope",               color: "EF7C8E") { path.append(AppRoute.especialistas) }
                AbrirCard(title: "Consultas",     subtitle: "Histórico e marcações",      icon: "calendar.badge.checkmark",  color: "F59E0B") { path.append(AppRoute.consultas) }
                AbrirCard(title: "Perfil",        subtitle: "A tua conta",               icon: "person.fill",               color: "667085") { path.append(AppRoute.profile) }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Consultas Recentes
    private var consultasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(title: "Consultas Recentes", icon: "calendar.badge.checkmark", color: "F59E0B")
                Spacer()
                Button { path.append(AppRoute.consultas) } label: {
                    Text("Ver todas").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: "2D8C82"))
                }
            }
            VStack(spacing: 10) { ForEach(vm.consultations.prefix(3)) { ConsultaRow(c: $0) } }
        }
        .padding(.horizontal, 16).padding(.bottom, 24)
    }

    // MARK: - Medições
    private var readingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Minhas Medições", icon: "waveform.path.ecg", color: "2D8C82")
            VStack(spacing: 10) { ForEach(vm.readings.prefix(4)) { ReadingRow(reading: $0) } }
        }
        .padding(.horizontal, 16).padding(.bottom, 24)
    }

    // MARK: - Medicação
    private var medsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Medicação Ativa", icon: "pills.fill", color: "8B5CF6")
            VStack(spacing: 10) { ForEach(vm.medications.prefix(4)) { MedicationRow(med: $0) } }
        }
        .padding(.horizontal, 16).padding(.bottom, 24)
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
        .padding(.horizontal, 16).padding(.bottom, 24)
    }

    // MARK: - O que podes fazer
    private var oPodeFazerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(title: "O que podes fazer", icon: "list.bullet.rectangle", color: "344054")
                .padding(.horizontal, 16)
            VStack(spacing: 0) {
                FazerRow(icon: "waveform.path.ecg",       color: "2D8C82", title: "Iniciar Triagem",             subtitle: "Descreve os sintomas e recebe orientação.")    { path.append(AppRoute.triagem) }
                Divider().padding(.leading, 62)
                FazerRow(icon: "calendar.badge.plus",     color: "3B82F6", title: "Marcar Consulta",             subtitle: "Escolhe especialidade, médico e horário.")     { path.append(AppRoute.especialistas) }
                Divider().padding(.leading, 62)
                FazerRow(icon: "video.fill",              color: "3B82F6", title: "Fazer Teleconsulta",          subtitle: "Consulta médica por vídeo, sem sair de casa.") { path.append(AppRoute.teleconsult) }
                Divider().padding(.leading, 62)
                FazerRow(icon: "arrow.clockwise.circle",  color: "8B5CF6", title: "Pedir Renovação de Receita",  subtitle: "Envia o pedido ao médico online.")             { path.append(AppRoute.receitas) }
                Divider().padding(.leading, 62)
                FazerRow(icon: "heart.text.square.fill",  color: "EF7C8E", title: "Acompanhar Saúde Crónica",    subtitle: "Medicação, sinais vitais e follow-ups.")       { path.append(AppRoute.triagem) }
                Divider().padding(.leading, 62)
                FazerRow(icon: "person.2.fill",           color: "667085", title: "Ver Especialistas",            subtitle: "Encontra médicos disponíveis na plataforma.")  { path.append(AppRoute.especialistas) }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - KPI Chip
private struct KPIChip: View {
    let value: String; let label: String; let icon: String; let color: String
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(Color(hex: color))
                Text(value).font(.system(size: 18, weight: .heavy)).foregroundStyle(Color(hex: "101828"))
            }
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(Color(hex: "667085"))
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Risk Badge
private struct RiskBadge: View {
    let risk: String
    var body: some View {
        Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
            .padding(.horizontal, 8).padding(.vertical, 3).background(color).clipShape(Capsule())
    }
    private var label: String {
        switch risk { case "URGENT": return "URGENTE"; case "HIGH": return "ALTO"; case "MEDIUM": return "MÉDIO"; default: return "BAIXO" }
    }
    private var color: Color {
        switch risk { case "URGENT": return Color(hex: "DC2626"); case "HIGH": return Color(hex: "EA580C"); case "MEDIUM": return Color(hex: "D97706"); default: return Color(hex: "16A34A") }
    }
}

// MARK: - Consulta Row
private struct ConsultaRow: View {
    let c: ConsultaItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(statusColor.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: statusIcon).font(.system(size: 18)).foregroundStyle(statusColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(c.specialty.capitalized).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                Text(statusLabel).font(.system(size: 12)).foregroundStyle(Color(hex: "667085"))
            }
            Spacer()
            if let d = c.scheduled_at { Text(fmtDate(d)).font(.system(size: 11)).foregroundStyle(Color(hex: "667085")) }
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    private var statusLabel: String {
        switch c.status { case "requested": return "Aguarda confirmação"; case "scheduled": return "Agendada"; case "in_progress": return "Em curso"; case "completed": return "Concluída"; case "cancelled": return "Cancelada"; default: return c.status.capitalized }
    }
    private var statusIcon: String {
        switch c.status { case "completed": return "checkmark.circle.fill"; case "cancelled": return "xmark.circle.fill"; case "in_progress": return "video.fill"; default: return "clock.fill" }
    }
    private var statusColor: Color {
        switch c.status { case "completed": return Color(hex: "16A34A"); case "cancelled": return Color(hex: "EF4444"); case "in_progress": return Color(hex: "3B82F6"); default: return Color(hex: "F59E0B") }
    }
    private func fmtDate(_ s: String) -> String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let d = f.date(from: s) else { return s }
        let o = DateFormatter(); o.dateFormat = "dd/MM HH:mm"; o.locale = Locale(identifier: "pt_PT"); return o.string(from: d)
    }
}

// MARK: - AbrirCard
private struct AbrirCard: View {
    let title: String; let subtitle: String; let icon: String; let color: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: color).opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(Color(hex: color))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: "101828"))
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")).lineLimit(2)
                }
                HStack(spacing: 4) {
                    Text("Abrir").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: color))
                    Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold)).foregroundStyle(Color(hex: color))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16).background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FazerRow
private struct FazerRow: View {
    let icon: String; let color: String; let title: String; let subtitle: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color(hex: color).opacity(0.12)).frame(width: 38, height: 38)
                    Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color(hex: color))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(Color(hex: "667085"))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: "C0CCDA"))
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
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

// MARK: - InfoRow
private struct InfoRow: View {
    let icon: String; let color: String; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Color(hex: color))
            Text(text).font(.system(size: 14)).foregroundStyle(Color(hex: "667085"))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Profile Sheet
struct ProfileView: View {
    @StateObject private var auth = AuthService.shared
    var body: some View {
        List {
            Section("Conta") {
                LabeledContent("Email", value: auth.profile?.email ?? "—")
                LabeledContent("Nome", value: auth.profile?.full_name ?? "—")
                LabeledContent("Tipo", value: auth.profile?.role?.capitalized ?? "—")
            }
            Section {
                Button(role: .destructive) { auth.logout() } label: {
                    Label("Terminar sessão", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Consultas Sheet
struct ConsultasView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm = ConsultasViewModel()
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.minus").font(.system(size: 48)).foregroundStyle(Color(hex: "A0AEC0"))
                    Text("Sem consultas registadas.").font(.system(size: 16)).foregroundStyle(Color(hex: "667085"))
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(vm.items) { c in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(c.specialty.capitalized).font(.system(size: 15, weight: .bold))
                            Spacer()
                            StatusPill(status: c.status)
                        }
                        if let d = c.scheduled_at { Text(fmtDate(d)).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("As Minhas Consultas")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(token: auth.token() ?? "") }
    }
    private func fmtDate(_ s: String) -> String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let d = f.date(from: s) else { return s }
        let o = DateFormatter(); o.dateStyle = .medium; o.timeStyle = .short; o.locale = Locale(identifier: "pt_PT")
        return o.string(from: d)
    }
}

private struct StatusPill: View {
    let status: String
    var body: some View {
        Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3).background(color.opacity(0.12)).clipShape(Capsule())
    }
    private var label: String {
        switch status { case "requested": return "Pendente"; case "scheduled": return "Agendada"; case "in_progress": return "Em curso"; case "completed": return "Concluída"; case "cancelled": return "Cancelada"; default: return status.capitalized }
    }
    private var color: Color {
        switch status { case "completed": return Color(hex: "16A34A"); case "cancelled": return Color(hex: "EF4444"); case "in_progress": return Color(hex: "3B82F6"); default: return Color(hex: "F59E0B") }
    }
}

// MARK: - Ecrãs de Serviços

// MARK: - Family Dependent (for triage selector)
struct FamilyDependent: Identifiable, Decodable, Hashable {
    let id: Int
    let full_name: String
    let relationship: String?
    var dependentId: String { String(id) }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FamilyDependent, rhs: FamilyDependent) -> Bool { lhs.id == rhs.id }
}

// MARK: - Triagem ViewModel
@MainActor
final class TriagemViewModel: ObservableObject {
    enum Step { case history, start, questions, result }

    @Published var step: Step = .history
    @Published var ageGroup = "adult"
    @Published var category = "general"
    @Published var complaint = ""
    @Published var questions: [TriageQuestion] = []
    @Published var boolAnswers: [String: Bool] = [:]
    @Published var numAnswers: [String: Double] = [:]
    @Published var selectAnswers: [String: String] = [:]
    @Published var result: TriageResultResp?
    @Published var history: [TriageHistoryItem] = []
    @Published var isLoading = false
    @Published var errorMsg = ""

    // Family selector
    @Published var dependents: [FamilyDependent] = []
    @Published var selectedDependentId: String = "me"

    // Vitals
    @Published var systolic: String = ""
    @Published var diastolic: String = ""
    @Published var spo2: String = ""
    @Published var temperature: String = ""
    @Published var glucose: String = ""

    private var triageId = ""
    private let base = KayaConfig.baseAPI

    func loadDependents(token: String) async {
        guard let url = URL(string: base + "/api/v1/family/") else { return }
        var req = URLRequest(url: url); req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let (data, _) = try? await URLSession.shared.data(for: req),
           let list = try? JSONDecoder().decode([FamilyDependent].self, from: data) {
            dependents = list
        }
    }

    // Vital thresholds (same as website)
    func vitalColor(_ key: String, _ val: Double?) -> Color {
        guard let val else { return .clear }
        let thresholds: [String: (Double, Double)] = [
            "systolic":    (90, 140),
            "diastolic":   (60, 90),
            "spo2":        (95, 100),
            "temperature": (36.0, 37.5),
            "glucose":     (70, 140),
        ]
        guard let (lo, hi) = thresholds[key] else { return Color(hex: "22C55E") }
        if val < lo || val > hi { return Color(hex: "EF4444") }
        if val == lo || val == hi { return Color(hex: "EAB308") }
        return Color(hex: "22C55E")
    }

    func loadHistory(token: String) async {
        guard let url = URL(string: base + "/api/v1/triage/history") else { return }
        var req = URLRequest(url: url); req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode([TriageHistoryItem].self, from: data) else { return }
        history = decoded
    }

    func deleteTriage(id: String, token: String) async {
        guard let url = URL(string: base + "/api/v1/triage/\(id)") else { return }
        var req = URLRequest(url: url); req.httpMethod = "DELETE"; req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: req)
        history.removeAll { $0.id == id }
    }

    func startTriage(token: String) async {
        errorMsg = ""; isLoading = true; defer { isLoading = false }
        guard !complaint.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Descreve a queixa principal."; return }
        guard let url = URL(string: base + "/api/v1/triage/start") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"; req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var bodyObj: [String: Any] = ["chief_complaint": complaint, "age_group": ageGroup, "category": category]
        if selectedDependentId != "me" { bodyObj["dependent_id"] = selectedDependentId }
        var vitalsObj: [String: Double] = [:]
        if let v = Double(systolic),     !systolic.isEmpty     { vitalsObj["systolic"]     = v }
        if let v = Double(diastolic),    !diastolic.isEmpty    { vitalsObj["diastolic"]    = v }
        if let v = Double(spo2),         !spo2.isEmpty         { vitalsObj["spo2"]         = v }
        if let v = Double(temperature),  !temperature.isEmpty  { vitalsObj["temperature"]  = v }
        if let v = Double(glucose),      !glucose.isEmpty      { vitalsObj["glucose"]      = v }
        if !vitalsObj.isEmpty { bodyObj["vital_signs"] = vitalsObj }

        req.httpBody = try? JSONSerialization.data(withJSONObject: bodyObj)
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let r = try? JSONDecoder().decode(TriageStartResp.self, from: data) else {
            errorMsg = "Não foi possível iniciar a triagem. Verifica a ligação."; return
        }
        triageId = r.triage_id; questions = r.questions
        boolAnswers = [:]; numAnswers = [:]; selectAnswers = [:]
        step = .questions
    }

    func submitAndComplete(token: String) async {
        errorMsg = ""; isLoading = true; defer { isLoading = false }
        var answersArr: [[String: Any]] = []
        for q in questions {
            if q.type == "boolean"       { answersArr.append(["question_key": q.key, "answer": boolAnswers[q.key] ?? false]) }
            else if q.type == "scale"    { answersArr.append(["question_key": q.key, "answer": Int(numAnswers[q.key] ?? 1)]) }
            else if q.type == "select"   { answersArr.append(["question_key": q.key, "answer": selectAnswers[q.key] ?? ""]) }
            else                         { answersArr.append(["question_key": q.key, "answer": Int(numAnswers[q.key] ?? 0)]) }
        }
        if let url = URL(string: base + "/api/v1/triage/\(triageId)/answers") {
            var req = URLRequest(url: url); req.httpMethod = "POST"
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: ["answers": answersArr])
            _ = try? await URLSession.shared.data(for: req)
        }
        guard let url2 = URL(string: base + "/api/v1/triage/\(triageId)/complete") else { return }
        var req2 = URLRequest(url: url2); req2.httpMethod = "POST"
        req2.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req2),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let r = try? JSONDecoder().decode(TriageResultResp.self, from: data) else {
            errorMsg = "Erro ao completar a triagem."; return
        }
        result = r; step = .result
    }
}

// ─────────────────────────────────────────────
// MARK: - Triagem View (fluxo real, espelha website)
// ─────────────────────────────────────────────
struct TriagemView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm = TriagemViewModel()

    // Question labels — PT, identical to website QUESTION_LABELS map
    static let questionLabels: [String: String] = [
        "age":                    "Qual é a sua idade?",
        "temperature":            "Temperatura corporal (°C) — 0 se não sabe",
        "chest_pain":             "Tem dor no peito?",
        "breathing_difficulty":   "Tem dificuldade em respirar?",
        "fainting":               "Desmaiou ou sentiu que ia desmaiar?",
        "stroke_signs":           "Apresenta sinais de AVC (dormência facial, dificuldade em falar, fraqueza num lado do corpo)?",
        "severe_bleeding":        "Tem hemorragia grave que não para?",
        "fever_days":             "Há quantos dias tem febre? (0 se não tem)",
        "pain_level":             "Nível de dor de 0 a 10",
        "chronic_conditions":     "Tem doenças crónicas (diabetes, hipertensão, asma, etc.)?",
        "pregnant":               "Está grávida ou pode estar grávida?",
        "symptoms_duration_hours":"Há quantas horas começaram os sintomas?",
        "fever":                  "Tem febre actualmente?",
        "shortness_of_breath":    "Tem falta de ar ou dificuldade em respirar?",
        "nausea":                 "Tem náuseas?",
        "vomiting":               "Tem vómitos?",
        "headache":               "Tem dor de cabeça?",
        "dizziness":              "Tem tonturas ou sensação de desmaio?",
        "abdominal_pain":         "Tem dor abdominal?",
        "pain_scale":             "Numa escala de 1 a 10, como classifica a dor?",
        "duration":               "Há quanto tempo tem estes sintomas?",
        "onset":                  "Os sintomas começaram de forma súbita ou gradual?",
        "previous_episodes":      "Já teve episódios semelhantes anteriormente?",
        "medications_taken":      "Tomou algum medicamento para aliviar os sintomas?",
        "allergic_reaction":      "Tem algum sinal de reacção alérgica (erupção, inchaço)?",
        "blood_pressure_high":    "Tem tensão arterial habitualmente elevada?",
        "heart_palpitations":     "Sente palpitações ou batimentos cardíacos irregulares?",
        "cough":                  "Tem tosse?",
        "productive_cough":       "A tosse é produtiva (com expetoração)?",
        "urinary_symptoms":       "Tem sintomas urinários (ardor, frequência, cor alterada)?",
        "skin_rash":              "Tem erupção cutânea ou alterações na pele?",
        "swelling":               "Tem inchaço em alguma parte do corpo?",
        "fatigue":                "Tem cansaço ou fadiga intensa?",
        "loss_of_consciousness":  "Perdeu ou quase perdeu a consciência?",
        "severity":               "Como avalia a gravidade geral do seu estado?",
        "chronic_condition_flare":"É um agravamento de uma condição crónica conhecida?",
        "appetite_loss":          "Perdeu o apetite?",
        "weight_loss":            "Tem perdido peso sem razão aparente?",
        "night_sweats":           "Tem suores nocturnos?",
        "blurred_vision":         "Tem visão turva ou alterações visuais?",
        "ear_pain":               "Tem dor de ouvido?",
        "sore_throat":            "Tem dor de garganta?",
        "runny_nose":             "Tem corrimento nasal?",
        "back_pain":              "Tem dor nas costas?",
        "joint_pain":             "Tem dor nas articulações?",
        "muscle_pain":            "Tem dores musculares?",
        "trauma":                 "Sofreu algum traumatismo ou queda recente?",
        "bleeding":               "Tem sangramento activo?",
        "confusion":              "Tem confusão mental ou desorientação?",
        "anxiety":                "Sente ansiedade ou ataques de pânico?",
        "depression_symptoms":    "Tem sentimentos de tristeza persistente ou depressão?",
    ]

    static let categories: [(String, String)] = [
        ("general",     "Geral"),
        ("respiratory", "Respiratório"),
        ("cardiac",     "Cardíaco"),
        ("neuro",       "Neurológico"),
        ("gi",          "Digestivo"),
        ("urinary",     "Urinário"),
        ("skin",        "Pele"),
        ("injury",      "Lesão"),
        ("mental",      "Saúde Mental"),
        ("womens",      "Saúde da Mulher"),
        ("medication",  "Medicação"),
        ("chronic",     "Crónico"),
    ]

    var body: some View {
        ZStack {
            Color(hex: "F5F7FA").ignoresSafeArea()
            Group {
                switch vm.step {
                case .history:   historyView
                case .start:     startView
                case .questions: questionsView
                case .result:    resultView
                }
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if vm.step != .history {
                    Button { vm.step = .history } label: { Image(systemName: "clock.arrow.circlepath") }
                }
            }
        }
        .task {
            await vm.loadHistory(token: auth.token() ?? "")
            await vm.loadDependents(token: auth.token() ?? "")
        }
    }

    private var navTitle: String {
        switch vm.step {
        case .history:   return "Historial de Triagens"
        case .start:     return "Nova Triagem"
        case .questions: return "Responde às perguntas"
        case .result:    return "Resultado"
        }
    }

    // ── HISTORY ─────────────────────────────────────
    private var historyView: some View {
        ScrollView {
            VStack(spacing: 14) {
                Button { vm.step = .start; vm.complaint = ""; vm.errorMsg = "" } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill").font(.system(size: 16, weight: .bold))
                        Text("Nova Triagem").font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity).padding(14).background(Color(hex: "2D8C82"))
                    .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                if vm.history.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "waveform.path.ecg").font(.system(size: 44)).foregroundStyle(Color(hex: "A0AEC0"))
                        Text("Sem triagens registadas").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color(hex: "344054"))
                        Text("Clica em Nova Triagem para descrever os teus sintomas.").font(.system(size: 13)).foregroundStyle(Color(hex: "667085")).multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ForEach(vm.history) { h in
                        TriagemHistoryRow(item: h) {
                            Task { await vm.deleteTriage(id: h.id, token: auth.token() ?? "") }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // ── START ────────────────────────────────────────
    private var startView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ServiceHero(icon: "waveform.path.ecg", color: "2D8C82", title: "Triagem Digital",
                            subtitle: "Descreve os teus sintomas. O motor de triagem avalia o risco e recomenda a ação adequada.")

                // ── Para quem é a triagem? ──────────────────
                forWhomSelector

                // Grupo etário
                VStack(alignment: .leading, spacing: 10) {
                    formLabel("Grupo Etário", icon: "person.fill")
                    HStack(spacing: 10) {
                        ForEach([("adult", "Adulto"), ("pediatric", "Pediátrico")], id: \.0) { (k, l) in
                            Button { vm.ageGroup = k } label: {
                                Text(l).font(.system(size: 13, weight: .semibold)).frame(maxWidth: .infinity).padding(10)
                                    .background(vm.ageGroup == k ? Color(hex: "2D8C82") : Color(hex: "F2F4F7"))
                                    .foregroundStyle(vm.ageGroup == k ? .white : Color(hex: "344054"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }.buttonStyle(.plain)
                        }
                    }
                }

                // Categoria
                VStack(alignment: .leading, spacing: 10) {
                    formLabel("Categoria", icon: "tag.fill")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TriagemView.categories, id: \.0) { (k, l) in
                                Button { vm.category = k } label: {
                                    Text(l).font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(vm.category == k ? Color(hex: "2D8C82") : Color(hex: "F2F4F7"))
                                        .foregroundStyle(vm.category == k ? .white : Color(hex: "344054"))
                                        .clipShape(Capsule())
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Queixa principal
                VStack(alignment: .leading, spacing: 8) {
                    formLabel("Queixa Principal", icon: "text.bubble.fill")
                    TextEditor(text: $vm.complaint)
                        .frame(minHeight: 100).padding(12)
                        .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "D0D5DD"), lineWidth: 1))
                        .font(.system(size: 14))
                }

                // Painel de Vitais
                vitalsPanel

                if !vm.errorMsg.isEmpty { ErrorBanner(msg: vm.errorMsg) }

                Button { Task { await vm.startTriage(token: auth.token() ?? "") } } label: {
                    HStack {
                        if vm.isLoading { ProgressView().tint(.white) }
                        else { Image(systemName: "chevron.right"); Text("Iniciar Triagem").font(.system(size: 16, weight: .bold)) }
                    }
                    .frame(maxWidth: .infinity).padding(16)
                    .background(vm.complaint.count >= 3 ? Color(hex: "2D8C82") : Color(hex: "A0AEC0"))
                    .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(vm.complaint.count < 3 || vm.isLoading)

                infoCard(icon: "exclamationmark.triangle.fill", color: "EF4444", title: "Em emergência?",
                         body: "Liga 112 ou dirige-te ao serviço de urgência mais próximo.")
                infoCard(icon: "lock.shield.fill", color: "2D8C82", title: "Dados Protegidos",
                         body: "Informação confidencial e protegida nos termos da lei.")
            }
            .padding(20)
        }
    }

    // ── Para Quem é a Triagem ─────────────────────────
    private var forWhomSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            formLabel("Para quem é a triagem?", icon: "person.2.fill")

            let relLabels: [String: String] = [
                "me": "Para mim",
                "son": "Filho", "daughter": "Filha",
                "mother": "Mãe", "father": "Pai",
                "brother": "Irmão", "sister": "Irmã",
                "other": "Outro familiar",
            ]

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // "Para mim" option
                    Button { vm.selectedDependentId = "me" } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle().fill(vm.selectedDependentId == "me" ? Color(hex: "2D8C82") : Color(hex: "F2F4F7"))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(vm.selectedDependentId == "me" ? .white : Color(hex: "667085"))
                            }
                            Text("Para mim").font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(vm.selectedDependentId == "me" ? Color(hex: "2D8C82") : Color(hex: "667085"))
                        }
                        .padding(.horizontal, 4)
                    }.buttonStyle(.plain)

                    // Family members from API
                    ForEach(vm.dependents) { dep in
                        let isSelected = vm.selectedDependentId == dep.dependentId
                        Button { vm.selectedDependentId = dep.dependentId } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle().fill(isSelected ? Color(hex: "2D8C82") : Color(hex: "F2F4F7"))
                                        .frame(width: 44, height: 44)
                                    Text(String(dep.full_name.prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(isSelected ? .white : Color(hex: "667085"))
                                }
                                Text(dep.full_name.components(separatedBy: " ").first ?? dep.full_name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color(hex: "2D8C82") : Color(hex: "667085"))
                                if let rel = dep.relationship, let label = relLabels[rel] {
                                    Text(label).font(.system(size: 9)).foregroundStyle(Color(hex: "A0AEC0"))
                                }
                            }
                            .padding(.horizontal, 4)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            // Selected badge
            if vm.selectedDependentId != "me",
               let dep = vm.dependents.first(where: { $0.dependentId == vm.selectedDependentId }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "2D8C82")).font(.system(size: 13))
                    Text("Triagem para \(dep.full_name)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "2D8C82"))
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(hex: "2D8C82").opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // ── Vitals Panel ─────────────────────────────────
    private var vitalsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill").font(.system(size: 13)).foregroundStyle(Color(hex: "EF4444"))
                Text("Sinais Vitais (opcional)").font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: "101828"))
                Spacer()
                Text("Preenche se tiveres equipamento").font(.system(size: 11)).foregroundStyle(Color(hex: "A0AEC0"))
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                vitalField(key: "systolic",    label: "Tensão Sistólica",  unit: "mmHg", icon: "heart.fill",      color: "EF4444", binding: $vm.systolic)
                vitalField(key: "diastolic",   label: "Tensão Diastólica", unit: "mmHg", icon: "heart.fill",      color: "EF4444", binding: $vm.diastolic)
                vitalField(key: "spo2",        label: "SpO₂",             unit: "%",    icon: "drop.fill",        color: "3B82F6", binding: $vm.spo2)
                vitalField(key: "temperature", label: "Temperatura",      unit: "°C",   icon: "thermometer",      color: "F59E0B", binding: $vm.temperature)
                vitalField(key: "glucose",     label: "Glicose",          unit: "mg/dL",icon: "chart.line.uptrend.xyaxis", color: "8B5CF6", binding: $vm.glucose)
            }
            // Preview badges with alert colors
            let badges = vitalBadges
            if !badges.isEmpty {
                FlowBadges(items: badges)
            }
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var vitalBadges: [(String, Color)] {
        var result: [(String, Color)] = []
        let fields: [(String, String, String)] = [
            ("systolic", vm.systolic, "mmHg"), ("diastolic", vm.diastolic, "mmHg"),
            ("spo2", vm.spo2, "%"), ("temperature", vm.temperature, "°C"), ("glucose", vm.glucose, "mg/dL")
        ]
        for (key, val, unit) in fields {
            if let v = Double(val), !val.isEmpty { result.append(("\(vitalShortLabel(key)): \(val) \(unit)", vm.vitalColor(key, v))) }
        }
        return result
    }

    private func vitalShortLabel(_ k: String) -> String {
        switch k { case "systolic": return "SBP"; case "diastolic": return "DBP"; case "spo2": return "SpO₂"; case "temperature": return "Temp"; case "glucose": return "Gli"; default: return k }
    }

    private func vitalField(key: String, label: String, unit: String, icon: String, color: String, binding: Binding<String>) -> some View {
        let dval = Double(binding.wrappedValue)
        let dotColor = dval.map { vm.vitalColor(key, $0) } ?? Color.clear
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(Color(hex: color))
                Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: "667085"))
                Spacer()
                if dval != nil { Circle().fill(dotColor).frame(width: 8, height: 8) }
            }
            HStack(spacing: 6) {
                TextField("—", text: binding).keyboardType(.decimalPad)
                    .font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(Color(hex: "F9FAFB")).clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(dval != nil ? dotColor.opacity(0.5) : Color(hex: "E4E7EC"), lineWidth: 1))
                Text(unit).font(.system(size: 10)).foregroundStyle(Color(hex: "A0AEC0"))
            }
        }
    }

    // ── QUESTIONS ────────────────────────────────────
    private var questionsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary bar
                HStack(spacing: 8) {
                    Text(vm.ageGroup == "adult" ? "Adulto" : "Pediátrico").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: "2D8C82"))
                        .padding(.horizontal, 10).padding(.vertical, 4).background(Color(hex: "2D8C82").opacity(0.1)).clipShape(Capsule())
                    Text(TriagemView.categories.first(where: { $0.0 == vm.category })?.1 ?? vm.category)
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: "667085"))
                        .padding(.horizontal, 10).padding(.vertical, 4).background(Color(hex: "F2F4F7")).clipShape(Capsule())
                    Spacer()
                    Text("\(vm.questions.count) perguntas").font(.system(size: 11)).foregroundStyle(Color(hex: "A0AEC0"))
                }

                Text("Queixa: \(vm.complaint)").font(.system(size: 13, weight: .medium)).foregroundStyle(Color(hex: "344054"))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12).background(.white).clipShape(RoundedRectangle(cornerRadius: 10))

                ForEach(Array(vm.questions.enumerated()), id: \.element.id) { (idx, q) in
                    questionCard(q, index: idx + 1)
                }

                if !vm.errorMsg.isEmpty { ErrorBanner(msg: vm.errorMsg) }

                HStack(spacing: 12) {
                    Button { vm.step = .start } label: {
                        HStack { Image(systemName: "arrow.left"); Text("Voltar") }
                            .font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).padding(14)
                            .background(Color(hex: "F2F4F7")).foregroundStyle(Color(hex: "344054")).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button { Task { await vm.submitAndComplete(token: auth.token() ?? "") } } label: {
                        HStack {
                            if vm.isLoading { ProgressView().tint(.white) }
                            else { Text("Obter Resultado").font(.system(size: 14, weight: .bold)) }
                        }
                        .frame(maxWidth: .infinity).padding(14).background(Color(hex: "2D8C82"))
                        .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(vm.isLoading)
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func questionCard(_ q: TriageQuestion, index: Int) -> some View {
        let label = TriagemView.questionLabels[q.key] ?? q.text
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(index)").font(.system(size: 11, weight: .heavy)).foregroundStyle(Color(hex: "2D8C82"))
                    .frame(width: 20, height: 20).background(Color(hex: "2D8C82").opacity(0.1)).clipShape(Circle())
                Text(label).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                    .fixedSize(horizontal: false, vertical: true)
                if q.required == true { Text("*").foregroundStyle(Color(hex: "EF4444")).font(.system(size: 12)) }
            }

            if q.type == "boolean" {
                HStack(spacing: 10) {
                    ForEach([("Sim", true), ("Não", false)], id: \.0) { (label, val) in
                        let selected = vm.boolAnswers[q.key] == val
                        Button { vm.boolAnswers[q.key] = val } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle").font(.system(size: 14))
                                Text(label).font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity).padding(10)
                            .background(selected ? (val ? Color(hex: "2D8C82") : Color(hex: "EF4444")) : Color(hex: "F2F4F7"))
                            .foregroundStyle(selected ? .white : Color(hex: "344054"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain)
                    }
                }
            } else if q.type == "scale" {
                // 1–10 scale buttons (like website)
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { n in
                            scaleButton(n: n, q: q)
                        }
                    }
                    HStack(spacing: 6) {
                        ForEach(6...10, id: \.self) { n in
                            scaleButton(n: n, q: q)
                        }
                    }
                    HStack {
                        Text("Sem dor").font(.system(size: 10)).foregroundStyle(Color(hex: "22C55E"))
                        Spacer()
                        Text("Dor máxima").font(.system(size: 10)).foregroundStyle(Color(hex: "EF4444"))
                    }
                }
            } else {
                // Number stepper
                HStack(spacing: 14) {
                    Button { if (vm.numAnswers[q.key] ?? 0) > 0 { vm.numAnswers[q.key, default: 0] -= 1 } } label: {
                        Image(systemName: "minus.circle.fill").font(.system(size: 28)).foregroundStyle(Color(hex: "2D8C82"))
                    }
                    Text(String(Int(vm.numAnswers[q.key] ?? 0))).font(.system(size: 22, weight: .bold)).frame(width: 60, alignment: .center)
                    Button { vm.numAnswers[q.key, default: 0] += 1 } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 28)).foregroundStyle(Color(hex: "2D8C82"))
                    }
                }
            }
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private func scaleButton(n: Int, q: TriageQuestion) -> some View {
        let selected = Int(vm.numAnswers[q.key] ?? 0) == n
        let scaleColor: Color = n <= 3 ? Color(hex: "22C55E") : n <= 6 ? Color(hex: "EAB308") : Color(hex: "EF4444")
        return Button { vm.numAnswers[q.key] = Double(n) } label: {
            Text("\(n)").font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(selected ? scaleColor : Color(hex: "F2F4F7"))
                .foregroundStyle(selected ? .white : Color(hex: "344054"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
    }

    // ── RESULT ───────────────────────────────────────
    @State private var showBookingSheet = false

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let r = vm.result {
                    resultHeader(r)
                    actionCard(r)
                    if let d = r.disclaimer { disclaimerCard(d) }

                    // Vitals review if entered
                    if !vitalBadges.isEmpty { vitalsReviewCard }

                    Button { showBookingSheet = true } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus").font(.system(size: 15, weight: .bold))
                            Text("Marcar Consulta com base neste resultado").font(.system(size: 15, weight: .bold))
                        }
                        .frame(maxWidth: .infinity).padding(16).background(Color(hex: "3B82F6"))
                        .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .sheet(isPresented: $showBookingSheet) {
                        BookConsultaSheet(specialty: "clinica_geral", doctorName: "Triagem Automática")
                    }

                    HStack(spacing: 12) {
                        Button { vm.step = .start; vm.complaint = ""; vm.result = nil } label: {
                            HStack { Image(systemName: "arrow.clockwise"); Text("Nova Triagem") }
                                .font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).padding(14)
                                .background(Color(hex: "F2F4F7")).foregroundStyle(Color(hex: "344054")).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button { vm.step = .history; Task { await vm.loadHistory(token: auth.token() ?? "") } } label: {
                            HStack { Image(systemName: "clock"); Text("Historial") }
                                .font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).padding(14)
                                .background(Color(hex: "F2F4F7")).foregroundStyle(Color(hex: "344054")).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private var vitalsReviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sinais Vitais Registados").font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: "344054"))
            FlowBadges(items: vitalBadges)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14)).shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // ── Result helpers (same colors as website) ──────
    private func resultHeader(_ r: TriageResultResp) -> some View {
        let (bg, fg, icon) = riskStyle(r.risk_level)
        return VStack(spacing: 14) {
            ZStack {
                Circle().fill(fg.opacity(0.12)).frame(width: 80, height: 80)
                    .overlay(Circle().stroke(fg, lineWidth: 2))
                Image(systemName: icon).font(.system(size: 32, weight: .semibold)).foregroundStyle(fg)
            }
            Text(riskLabel(r.risk_level)).font(.system(size: 26, weight: .heavy)).foregroundStyle(fg)
            Text("Score: \(Int(r.score)) / 100").font(.system(size: 14)).foregroundStyle(Color(hex: "667085"))
        }
        .frame(maxWidth: .infinity).padding(28).background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(fg.opacity(0.3), lineWidth: 1.5))
    }

    private func actionCard(_ r: TriageResultResp) -> some View {
        let (_, fg, _) = riskStyle(r.risk_level)
        return HStack(spacing: 14) {
            Image(systemName: "arrow.right.circle.fill").font(.system(size: 28)).foregroundStyle(fg)
            VStack(alignment: .leading, spacing: 4) {
                Text("Ação Recomendada").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: "667085"))
                Text(actionLabel(r.recommended_action)).font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: "101828"))
            }
            Spacer()
        }
        .padding(18).background(riskStyle(r.risk_level).0)
        .clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(fg.opacity(0.2), lineWidth: 1))
    }

    private func disclaimerCard(_ d: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill").font(.system(size: 20)).foregroundStyle(Color(hex: "F59E0B"))
            Text(d).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14).background(Color(hex: "FFFBEB")).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FDE68A"), lineWidth: 1))
    }

    private func infoCard(icon: String, color: String, title: String, body: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(Color(hex: color))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: "101828"))
                Text(body).font(.system(size: 12)).foregroundStyle(Color(hex: "667085"))
            }
            Spacer()
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func formLabel(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: "344054"))
    }

    // Risk colors matching website exactly
    private func riskStyle(_ r: String) -> (Color, Color, String) {
        switch r.uppercased() {
        case "URGENT": return (Color(hex: "FEF2F2"), Color(hex: "EF4444"), "exclamationmark.triangle.fill")
        case "HIGH":   return (Color(hex: "FFF7ED"), Color(hex: "F97316"), "exclamationmark.circle.fill")
        case "MEDIUM": return (Color(hex: "FEFCE8"), Color(hex: "EAB308"), "clock.badge.exclamationmark")
        default:       return (Color(hex: "F0FDF4"), Color(hex: "22C55E"), "checkmark.circle.fill")
        }
    }
    private func riskLabel(_ r: String) -> String {
        switch r.uppercased() { case "URGENT": return "URGENTE"; case "HIGH": return "Alto Risco"; case "MEDIUM": return "Risco Moderado"; default: return "Baixo Risco" }
    }
    private func actionLabel(_ a: String) -> String {
        switch a { case "ER_NOW": return "🚨 Vai às Urgências agora"; case "DOCTOR_NOW": return "Consulta médica imediata"; case "DOCTOR_24H": return "Consulta médica nas próximas 24h"; default: return "✅ Auto-cuidado — monitoriza os sintomas" }
    }
}

// MARK: - Triage History Row
private struct TriagemHistoryRow: View {
    let item: TriageHistoryItem
    let onDelete: () -> Void
    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(riskColor.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: riskIcon).font(.system(size: 18)).foregroundStyle(riskColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.chief_complaint ?? "Triagem").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828")).lineLimit(2)
                HStack(spacing: 6) {
                    if let r = item.risk_level {
                        Text(r).font(.system(size: 11, weight: .bold)).foregroundStyle(riskColor)
                            .padding(.horizontal, 7).padding(.vertical, 2).background(riskColor.opacity(0.1)).clipShape(Capsule())
                    }
                    Text(fmt(item.created_at)).font(.system(size: 11)).foregroundStyle(Color(hex: "A0AEC0"))
                }
            }
            Spacer()
            if confirmDelete {
                HStack(spacing: 6) {
                    Button { onDelete() } label: {
                        Text("Eliminar").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4).background(Color(hex: "EF4444")).clipShape(Capsule())
                    }
                    Button { confirmDelete = false } label: {
                        Text("Cancelar").font(.system(size: 11)).foregroundStyle(Color(hex: "667085"))
                    }
                }
            } else {
                Button { confirmDelete = true } label: {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundStyle(Color(hex: "A0AEC0"))
                }
            }
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var riskColor: Color {
        switch (item.risk_level ?? "").uppercased() { case "URGENT": return Color(hex: "EF4444"); case "HIGH": return Color(hex: "F97316"); case "MEDIUM": return Color(hex: "EAB308"); default: return Color(hex: "22C55E") }
    }
    private var riskIcon: String {
        switch (item.risk_level ?? "").uppercased() { case "URGENT", "HIGH": return "exclamationmark.triangle.fill"; case "MEDIUM": return "clock.fill"; default: return "checkmark.circle.fill" }
    }
    private func fmt(_ s: String) -> String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let d = f.date(from: s) else { return s }
        let o = DateFormatter(); o.dateStyle = .short; o.timeStyle = .short; o.locale = Locale(identifier: "pt_PT"); return o.string(from: d)
    }
}

// MARK: - FlowBadges (vitals display)
private struct FlowBadges: View {
    let items: [(String, Color)]
    var body: some View {
        // Simple horizontal wrapping with LazyVGrid
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 6)], spacing: 6) {
            ForEach(items, id: \.0) { (label, color) in
                Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(color)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(color.opacity(0.1)).clipShape(Capsule())
                    .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
            }
        }
    }
}

private struct ErrorBanner: View {
    let msg: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill").foregroundStyle(Color(hex: "DC2626"))
            Text(msg).font(.system(size: 13)).foregroundStyle(Color(hex: "DC2626"))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(Color(hex: "FEF2F2")).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


// MARK: - Teleconsulta View (booking real)
struct TeleconsultaView: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var specialty = "clinica_geral"
    @State private var scheduledDate = Date().addingTimeInterval(86400)
    @State private var isLoading = false
    @State private var errorMsg = ""
    @State private var booked = false
    @State private var bookedId = ""

    private let specialties = [
        ("clinica_geral",      "Clínica Geral"),
        ("cardiologia",        "Cardiologia"),
        ("dermatologia",       "Dermatologia"),
        ("pediatria",          "Pediatria"),
        ("ginecologia",        "Ginecologia"),
        ("psiquiatria",        "Psiquiatria"),
        ("neurologia",         "Neurologia"),
        ("ortopedia",          "Ortopedia"),
        ("oftalmologia",       "Oftalmologia"),
        ("urologia",           "Urologia"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ServiceHero(icon: "video.fill", color: "3B82F6", title: "Teleconsulta",
                            subtitle: "Consulta médica por videochamada. Agenda agora e o médico irá confirmar o horário.")

                if booked {
                    bookedConfirmation
                } else {
                    bookingForm
                }
            }
            .padding(20)
        }
        .background(Color(hex: "F5F7FA").ignoresSafeArea())
        .navigationTitle("Teleconsulta")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bookingForm: some View {
        VStack(spacing: 16) {
            // Specialty picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Especialidade").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "344054"))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(specialties, id: \.0) { (key, label) in
                            Button { specialty = key } label: {
                                Text(label).font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(specialty == key ? Color(hex: "3B82F6") : Color(hex: "F2F4F7"))
                                    .foregroundStyle(specialty == key ? .white : Color(hex: "344054"))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Date picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Data preferida").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "344054"))
                DatePicker("", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact).labelsHidden()
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            }

            if !errorMsg.isEmpty { ErrorBanner(msg: errorMsg) }

            Button { Task { await bookTeleconsulta() } } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    else { Image(systemName: "video.badge.plus"); Text("Agendar Teleconsulta").font(.system(size: 16, weight: .bold)) }
                }
                .frame(maxWidth: .infinity).padding(16).background(Color(hex: "3B82F6"))
                .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isLoading)

            infoBox(icon: "info.circle.fill", color: "3B82F6", text: "Após o agendamento, um médico irá aceitar e confirmar o horário. Receberás uma notificação.")
            infoBox(icon: "exclamationmark.triangle.fill", color: "EF4444", text: "Em emergência: liga 112 ou vai às urgências.")
        }
    }

    private var bookedConfirmation: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color(hex: "3B82F6").opacity(0.12)).frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(Color(hex: "3B82F6"))
            }
            Text("Teleconsulta Agendada!").font(.system(size: 22, weight: .heavy)).foregroundStyle(Color(hex: "101828"))
            Text("A tua consulta foi registada. Aguarda confirmação do médico.").font(.system(size: 14)).foregroundStyle(Color(hex: "667085")).multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 6) {
                Label(specialties.first(where: { $0.0 == specialty })?.1 ?? specialty, systemImage: "stethoscope")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "344054"))
                Label(formatDate(scheduledDate), systemImage: "calendar")
                    .font(.system(size: 14)).foregroundStyle(Color(hex: "667085"))
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            Button { dismiss() } label: {
                Text("Fechar").font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity).padding(16)
                    .background(Color(hex: "3B82F6")).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func infoBox(icon: String, color: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Color(hex: color))
            Text(text).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bookTeleconsulta() async {
        errorMsg = ""; isLoading = true; defer { isLoading = false }
        guard let token = auth.token(), let url = URL(string: KayaConfig.baseAPI + "/api/v1/consultations/book") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"; req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime]
        let body: [String: Any] = ["specialty": specialty, "scheduled_at": iso.string(from: scheduledDate), "next_available": false]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let code = (resp as? HTTPURLResponse)?.statusCode else { errorMsg = "Sem ligação ao servidor."; return }
        if code == 200 || code == 201 {
            booked = true
        } else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "Erro \(code)"
            errorMsg = msg
        }
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .long; f.timeStyle = .short; f.locale = Locale(identifier: "pt_PT"); return f.string(from: d)
    }
}

struct ReceitasView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm = ReceitasViewModel()
    var body: some View {
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
        .task { await vm.load(token: auth.token() ?? "") }
    }
}

struct EspecialistasView: View {
    @StateObject private var vm = EspecialistasViewModel()
    @StateObject private var auth = AuthService.shared
    @State private var bookingDoctor: DoctorItem?
    @State private var showBooking = false
    @State private var filterSpec = ""

    private var filtered: [DoctorItem] {
        guard !filterSpec.isEmpty else { return vm.doctors }
        return vm.doctors.filter { $0.specialization.lowercased().contains(filterSpec.lowercased()) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ServiceHero(icon: "stethoscope", color: "EF7C8E", title: "Especialistas",
                            subtitle: "Encontra médicos verificados disponíveis para consulta.")
                // Search/filter
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(Color(hex: "A0AEC0"))
                    TextField("Filtrar por especialidade…", text: $filterSpec)
                }
                .padding(12).background(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)

                if vm.isLoading {
                    ProgressView().padding(.top, 40)
                } else if vm.doctors.isEmpty {
                    ComingSoonCard(message: "Nenhum médico verificado disponível de momento.")
                } else if filtered.isEmpty {
                    InfoRow(icon: "magnifyingglass", color: "A0AEC0", text: "Nenhum resultado para \"\(filterSpec)\".")
                } else {
                    VStack(spacing: 14) {
                        ForEach(filtered) { doc in
                            DoctorCard(doc: doc) {
                                bookingDoctor = doc
                                showBooking = true
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(hex: "F5F7FA").ignoresSafeArea())
        .navigationTitle("Especialistas")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(token: auth.token() ?? "") }
        .sheet(isPresented: $showBooking) {
            if let doc = bookingDoctor {
                BookConsultaSheet(specialty: doc.specialization, doctorName: doc.display_name ?? "Médico")
            }
        }
    }
}

// MARK: - Shared Sub-views
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
            ZStack { Circle().fill(Color(hex: "8B5CF6").opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: "pills.fill").font(.system(size: 18)).foregroundStyle(Color(hex: "8B5CF6")) }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.medication_name ?? "Receita").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                if let s = item.status { Text(s.capitalized).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
            }
            Spacer()
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct DoctorCard: View {
    let doc: DoctorItem
    let onBook: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: "EF7C8E").opacity(0.12)).frame(width: 52, height: 52)
                    Text(initials).font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: "EF7C8E"))
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text((doc.title ?? "Dr.") + " " + (doc.display_name ?? "Médico"))
                            .font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: "101828"))
                        if doc.verification_status == "verified" {
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundStyle(Color(hex: "3B82F6"))
                        }
                    }
                    Text(specLabel(doc.specialization)).font(.system(size: 13)).foregroundStyle(Color(hex: "667085"))
                    if let city = doc.location_city { Text("📍 " + city).font(.system(size: 12)).foregroundStyle(Color(hex: "A0AEC0")) }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                if let exp = doc.years_experience {
                    Label("\(exp) anos", systemImage: "clock").font(.system(size: 11, weight: .medium)).foregroundStyle(Color(hex: "667085"))
                }
                if let min = doc.price_min, let max = doc.price_max {
                    Label("\(min)–\(max)€", systemImage: "eurosign.circle").font(.system(size: 11, weight: .medium)).foregroundStyle(Color(hex: "667085"))
                }
                Spacer()
                if doc.accepts_new_patients == true {
                    Text("Aceita novos").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color(hex: "16A34A"))
                        .padding(.horizontal, 8).padding(.vertical, 3).background(Color(hex: "F0FDF4")).clipShape(Capsule())
                }
            }
            if let bio = doc.bio, !bio.isEmpty {
                Text(bio).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")).lineLimit(2)
            }
            Button(action: onBook) {
                HStack {
                    Image(systemName: "calendar.badge.plus").font(.system(size: 13, weight: .bold))
                    Text("Marcar Consulta").font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity).padding(10).background(Color(hex: "EF7C8E"))
                .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    private var initials: String { String(doc.display_name?.prefix(1) ?? "M").uppercased() }
    private func specLabel(_ s: String) -> String { s.replacingOccurrences(of: "_", with: " ").capitalized }
}

// MARK: - Book Consulta Sheet
struct BookConsultaSheet: View {
    let specialty: String
    let doctorName: String
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var scheduledDate = Date().addingTimeInterval(86400)
    @State private var isLoading = false
    @State private var booked = false
    @State private var errorMsg = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if booked {
                        bookedView
                    } else {
                        formView
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "F5F7FA").ignoresSafeArea())
            .navigationTitle("Marcar Consulta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
        }
    }

    private var formView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack { Circle().fill(Color(hex: "EF7C8E").opacity(0.12)).frame(width: 52, height: 52)
                    Image(systemName: "stethoscope").font(.system(size: 22)).foregroundStyle(Color(hex: "EF7C8E")) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(doctorName).font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: "101828"))
                    Text(specialty.replacingOccurrences(of: "_", with: " ").capitalized).font(.system(size: 13)).foregroundStyle(Color(hex: "667085"))
                }
                Spacer()
            }
            .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                Text("Data e hora preferida").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "344054"))
                DatePicker("", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical).labelsHidden()
                    .padding(12).background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !errorMsg.isEmpty { ErrorBanner(msg: errorMsg) }

            Button { Task { await book() } } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    else { Image(systemName: "calendar.badge.plus"); Text("Confirmar Marcação").font(.system(size: 16, weight: .bold)) }
                }
                .frame(maxWidth: .infinity).padding(16).background(Color(hex: "2D8C82"))
                .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isLoading)
        }
    }

    private var bookedView: some View {
        VStack(spacing: 20) {
            ZStack { Circle().fill(Color(hex: "2D8C82").opacity(0.12)).frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(Color(hex: "2D8C82")) }
            Text("Consulta Marcada!").font(.system(size: 22, weight: .heavy)).foregroundStyle(Color(hex: "101828"))
            Text("Aguarda a confirmação do médico. Irás receber uma notificação.").font(.system(size: 14)).foregroundStyle(Color(hex: "667085")).multilineTextAlignment(.center)
            Button { dismiss() } label: {
                Text("Fechar").font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity).padding(16)
                    .background(Color(hex: "2D8C82")).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func book() async {
        errorMsg = ""; isLoading = true; defer { isLoading = false }
        guard let token = auth.token(), let url = URL(string: KayaConfig.baseAPI + "/api/v1/consultations/book") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"; req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime]
        let body: [String: Any] = ["specialty": specialty, "scheduled_at": iso.string(from: scheduledDate), "next_available": false]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let code = (resp as? HTTPURLResponse)?.statusCode else { errorMsg = "Sem ligação."; return }
        if code == 200 || code == 201 { booked = true }
        else { errorMsg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "Erro \(code)" }
    }
}

// MARK: - Data Models
struct PatientState: Decodable {
    let current_state: String
    let state_label: String
    let last_triage_risk: String?
    let last_triage_action: String?
    let last_triage_complaint: String?
    let last_triage_score: Double?
    let last_triage_date: String?
    let next_action: String
    let next_action_label: String
    let next_action_urgency: String
    let next_action_deadline: String?
    let triage_count: Int
    let consultation_count: Int
    let completed_consultations: Int
    let pending_consultations: Int
    let resolution_rate: Double?
}

struct DashboardKPIs: Decodable {
    let total_triage_sessions: Int
    let total_consultations: Int
    let total_patients: Int
    let total_doctors: Int
    let consultations_today: Int
    let avg_triage_score: Double?
}

struct ConsultaItem: Identifiable, Decodable {
    let id: String
    let specialty: String
    let status: String
    let scheduled_at: String?
    let payment_status: String
    let created_at: String
}

struct ReadingsResponse: Decodable { let readings: [DeviceReadingItem]; let total: Int? }
struct DeviceReadingItem: Identifiable, Decodable { let id: String; let reading_type: String; let value: Double; let unit: String?; let measured_at: String? }
struct MedicationItem: Identifiable, Decodable { let id: String; let medication_name: String; let dosage: String?; let frequency: String?; let is_active: Bool? }
struct NotifItem: Identifiable, Decodable { let id: String; let title: String?; let message: String?; let is_read: Bool? }
struct PrescriptionItem: Identifiable, Decodable { let id: String; let medication_name: String?; let status: String?; let created_at: String? }
struct DoctorItem: Identifiable, Decodable {
    let id: String
    let display_name: String?
    let title: String?
    let specialization: String
    let bio: String?
    let location_city: String?
    let years_experience: Int?
    let accepts_new_patients: Bool?
    let price_min: Int?
    let price_max: Int?
    let verification_status: String
}

// MARK: - Triage Models
struct TriageQuestion: Identifiable, Decodable {
    let key: String
    let text: String
    let type: String
    let required: Bool?
    let options: [String]?
    var id: String { key }
}
struct TriageStartResp: Decodable {
    let triage_id: String
    let status: String
    let questions: [TriageQuestion]
}
struct TriageResultResp: Decodable {
    let triage_id: String
    let risk_level: String
    let recommended_action: String
    let score: Double
    let disclaimer: String?
}
struct TriageHistoryItem: Identifiable, Decodable {
    let id: String
    let status: String
    let chief_complaint: String?
    let risk_level: String?
    let recommended_action: String?
    let score: Double?
    let created_at: String
}

// MARK: - Dashboard ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var kpis:          DashboardKPIs?
    @Published var patientState:  PatientState?
    @Published var consultations: [ConsultaItem]      = []
    @Published var readings:      [DeviceReadingItem] = []
    @Published var medications:   [MedicationItem]    = []
    @Published var notifications: [NotifItem]         = []
    @Published var isLoading = false

    var unreadNotifCount: Int { notifications.filter { $0.is_read != true }.count }

    private let base = KayaConfig.baseAPI

    func loadAll(token: String) async {
        guard !token.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        async let a: Void = fetchKPIs(token: token)
        async let b: Void = fetchState(token: token)
        async let c: Void = fetchConsultas(token: token)
        async let d: Void = fetchReadings(token: token)
        async let e: Void = fetchMeds(token: token)
        async let f: Void = fetchNotifs(token: token)
        _ = await (a, b, c, d, e, f)
    }

    private func get<T: Decodable>(_ path: String, token: String, as type: T.Type) async -> T? {
        guard let url = URL(string: base + path) else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func fetchKPIs(token: String) async     { kpis         = await get("/api/v1/dashboard/kpis",         token: token, as: DashboardKPIs.self) }
    private func fetchState(token: String) async    { patientState  = await get("/api/v1/dashboard/patient-state",token: token, as: PatientState.self) }
    private func fetchConsultas(token: String) async { consultations = await get("/api/v1/consultations/me",      token: token, as: [ConsultaItem].self) ?? [] }
    private func fetchReadings(token: String) async {
        if let r = await get("/api/v1/readings/me", token: token, as: ReadingsResponse.self) { readings = r.readings }
    }
    private func fetchMeds(token: String) async     { medications   = await get("/api/v1/medications/me",        token: token, as: [MedicationItem].self) ?? [] }
    private func fetchNotifs(token: String) async   { notifications = await get("/api/v1/notifications/me",      token: token, as: [NotifItem].self) ?? [] }
}

@MainActor final class ConsultasViewModel: ObservableObject {
    @Published var items: [ConsultaItem] = []
    @Published var isLoading = false
    func load(token: String) async {
        isLoading = true; defer { isLoading = false }
        guard let url = URL(string: KayaConfig.baseAPI + "/api/v1/consultations/me"), !token.isEmpty else { return }
        var req = URLRequest(url: url); req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode([ConsultaItem].self, from: data) else { return }
        items = decoded
    }
}

@MainActor final class ReceitasViewModel: ObservableObject {
    @Published var items: [PrescriptionItem] = []
    @Published var isLoading = false
    func load(token: String) async {
        isLoading = true; defer { isLoading = false }
        guard let url = URL(string: KayaConfig.baseAPI + "/api/v1/prescriptions/me"), !token.isEmpty else { return }
        var req = URLRequest(url: url); req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode([PrescriptionItem].self, from: data) else { return }
        items = decoded
    }
}

@MainActor final class EspecialistasViewModel: ObservableObject {
    @Published var doctors: [DoctorItem] = []
    @Published var isLoading = false
    func load(token: String) async {
        isLoading = true; defer { isLoading = false }
        guard let url = URL(string: KayaConfig.baseAPI + "/api/v1/doctors/") else { return }
        var req = URLRequest(url: url); req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode([DoctorItem].self, from: data) else { return }
        doctors = decoded
    }
}

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
            Text(valueText).font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: "101828"))
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    private var valueText: String {
        let f = reading.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"
        return String(format: f, reading.value) + " " + (reading.unit ?? "")
    }
    private var readingIcon: String {
        switch reading.reading_type.lowercased() { case "blood_pressure": return "heart.fill"; case "glucose": return "drop.fill"; case "temperature": return "thermometer"; case "weight": return "scalemass.fill"; default: return "waveform.path.ecg" }
    }
    private var readingColor: Color {
        switch reading.reading_type.lowercased() { case "blood_pressure": return Color(hex: "EF4444"); case "glucose": return Color(hex: "F59E0B"); case "temperature": return Color(hex: "3B82F6"); case "weight": return Color(hex: "8B5CF6"); default: return Color(hex: "2D8C82") }
    }
    private var readingLabel: String {
        switch reading.reading_type.lowercased() { case "blood_pressure": return "Pressão Arterial"; case "glucose": return "Glicose"; case "temperature": return "Temperatura"; case "weight": return "Peso"; case "heart_rate": return "Freq. Cardíaca"; default: return reading.reading_type.replacingOccurrences(of: "_", with: " ").capitalized }
    }
    private func fmt(_ s: String) -> String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let d = f.date(from: s) else { return s }
        let o = DateFormatter(); o.dateFormat = "dd MMM, HH:mm"; o.locale = Locale(identifier: "pt_PT"); return o.string(from: d)
    }
}

// MARK: - MedicationRow
private struct MedicationRow: View {
    let med: MedicationItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(Color(hex: "8B5CF6").opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: "pills.fill").font(.system(size: 18)).foregroundStyle(Color(hex: "8B5CF6")) }
            VStack(alignment: .leading, spacing: 2) {
                Text(med.medication_name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                if let d = med.dosage { Text(d + (med.frequency.map { " · " + $0 } ?? "")).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
            }
            Spacer()
            if med.is_active == true {
                Text("Activo").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: "2D8C82"))
                    .padding(.horizontal, 10).padding(.vertical, 4).background(Color(hex: "2D8C82").opacity(0.1)).clipShape(Capsule())
            }
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - NotificationRow
private struct NotificationRow: View {
    let notif: NotifItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(Color(hex: "F59E0B").opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: notif.is_read == true ? "bell" : "bell.badge.fill").font(.system(size: 18)).foregroundStyle(Color(hex: "F59E0B")) }
            VStack(alignment: .leading, spacing: 2) {
                if let t = notif.title { Text(t).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828")) }
                if let m = notif.message { Text(m).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")).lineLimit(2) }
            }
            Spacer()
            if notif.is_read != true { Circle().fill(Color(hex: "2D8C82")).frame(width: 8, height: 8) }
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
