import SwiftUI

// MARK: - Dashboard Principal
struct MainDashboardView: View {
    @StateObject private var auth  = AuthService.shared
    @StateObject private var vm    = DashboardViewModel()
    @State private var showProfile     = false
    @State private var showTriagem     = false
    @State private var showTeleconsult = false
    @State private var showReceitas    = false
    @State private var showEspecialis  = false
    @State private var showConsultas   = false

    var body: some View {
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
        }
        .sheet(isPresented: $showProfile)     { ProfileView() }
        .sheet(isPresented: $showTriagem)     { TriagemView() }
        .sheet(isPresented: $showTeleconsult) { TeleconsultaView() }
        .sheet(isPresented: $showReceitas)    { ReceitasView() }
        .sheet(isPresented: $showEspecialis)  { EspecialistasView() }
        .sheet(isPresented: $showConsultas)   { ConsultasView() }
        .task { await vm.loadAll(token: auth.token() ?? "") }
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
            Button { auth.logout() } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17)).foregroundStyle(Color(hex: "667085")).padding(8)
            }
            Button { showProfile = true } label: {
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
                    case "start_triage", "complete_triage": showTriagem = true
                    case "book_consultation": showEspecialis = true
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
                AbrirCard(title: "Triagem",       subtitle: "Avalia os teus sintomas",   icon: "waveform.path.ecg",         color: "2D8C82") { showTriagem     = true }
                AbrirCard(title: "Teleconsulta",  subtitle: "Consulta por vídeo",         icon: "video.fill",                color: "3B82F6") { showTeleconsult = true }
                AbrirCard(title: "Receitas",      subtitle: "As tuas prescrições",        icon: "pills.fill",                color: "8B5CF6") { showReceitas    = true }
                AbrirCard(title: "Especialistas", subtitle: "Encontra médicos",           icon: "stethoscope",               color: "EF7C8E") { showEspecialis  = true }
                AbrirCard(title: "Consultas",     subtitle: "Histórico e marcações",      icon: "calendar.badge.checkmark",  color: "F59E0B") { showConsultas   = true }
                AbrirCard(title: "Perfil",        subtitle: "A tua conta",               icon: "person.fill",               color: "667085") { showProfile     = true }
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
                Button { showConsultas = true } label: {
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
                FazerRow(icon: "waveform.path.ecg",       color: "2D8C82", title: "Iniciar Triagem",             subtitle: "Descreve os sintomas e recebe orientação.")    { showTriagem     = true }
                Divider().padding(.leading, 62)
                FazerRow(icon: "calendar.badge.plus",     color: "3B82F6", title: "Marcar Consulta",             subtitle: "Escolhe especialidade, médico e horário.")     { showEspecialis  = true }
                Divider().padding(.leading, 62)
                FazerRow(icon: "video.fill",              color: "3B82F6", title: "Fazer Teleconsulta",          subtitle: "Consulta médica por vídeo, sem sair de casa.") { showTeleconsult = true }
                Divider().padding(.leading, 62)
                FazerRow(icon: "arrow.clockwise.circle",  color: "8B5CF6", title: "Pedir Renovação de Receita",  subtitle: "Envia o pedido ao médico online.")             { showReceitas    = true }
                Divider().padding(.leading, 62)
                FazerRow(icon: "heart.text.square.fill",  color: "EF7C8E", title: "Acompanhar Saúde Crónica",    subtitle: "Medicação, sinais vitais e follow-ups.")       { showTriagem     = true }
                Divider().padding(.leading, 62)
                FazerRow(icon: "person.2.fill",           color: "667085", title: "Ver Especialistas",            subtitle: "Encontra médicos disponíveis na plataforma.")  { showEspecialis  = true }
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

// MARK: - Consultas Sheet
struct ConsultasView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm = ConsultasViewModel()
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
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
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
            .task { await vm.load(token: auth.token() ?? "") }
        }
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
struct TriagemView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ServiceHero(icon: "waveform.path.ecg", color: "2D8C82", title: "Triagem", subtitle: "Descreve os teus sintomas e recebe orientação médica rápida.")
                    ComingSoonCard(message: "A triagem de sintomas está em desenvolvimento. Em breve poderás descrever sintomas e obter orientação clínica imediata.")
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
                    ComingSoonCard(message: "As videoconsultas estão em desenvolvimento. Em breve poderás agendar e entrar numa consulta directamente aqui.")
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

private struct DoctorRow: View {
    let doc: DoctorItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(Color(hex: "EF7C8E").opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: "stethoscope").font(.system(size: 18)).foregroundStyle(Color(hex: "EF7C8E")) }
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
struct DoctorItem: Identifiable, Decodable { let id: String; let full_name: String?; let specialty: String?; let is_available: Bool? }

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
        guard let url = URL(string: KayaConfig.baseAPI + "/api/v1/doctors"), !token.isEmpty else { return }
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
