import SwiftUI

// MARK: - Dashboard Principal (ecrã único após login)
struct MainDashboardView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm   = DashboardViewModel()
    @State private var webURL: IdentifiableURL?    // sheet WebView para serviços
    @State private var showProfile = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "F7FAFC").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 64)   // espaço topBar
                    heroCard
                    quickAccess
                    if !vm.readings.isEmpty    { sectionReadings }
                    if !vm.medications.isEmpty { sectionMedications }
                    sectionNotifications
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
            }
            .refreshable { await vm.load(token: auth.token() ?? "") }

            topBar
        }
        .sheet(item: $webURL) { w in ServiceWebView(url: w.url) }
        .sheet(isPresented: $showProfile) { ProfileView() }
        .task { await vm.load(token: auth.token() ?? "") }
    }

    // MARK: TopBar
    private var topBar: some View {
        HStack(spacing: 0) {
            // Avatar / Perfil
            Button { showProfile = true } label: {
                Circle()
                    .fill(Color(hex: "2D8C82").opacity(0.15))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Text(String(auth.profile?.full_name?.prefix(1) ?? auth.profile?.email?.prefix(1) ?? "?").uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "2D8C82"))
                    )
            }
            .padding(.leading, 16)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "2D8C82"))
                Text("KAYA")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Color(hex: "101828"))
            }

            Spacer()

            // Logout
            Button { auth.logout() } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "EF4444"))
            }
            .padding(.trailing, 16)
        }
        .frame(height: 56)
        .background(.ultraThinMaterial)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: Hero
    private var heroCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(auth.profile?.full_name?.prefix(1) ?? auth.profile?.email?.prefix(1) ?? "?").uppercased())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("Olá, \(firstName) 👋")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Como te sentes hoje?")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(20)
        .background(LinearGradient(
            colors: [Color(hex: "2D8C82"), Color(hex: "1B6B62")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color(hex: "2D8C82").opacity(0.35), radius: 14, x: 0, y: 7)
    }

    private var firstName: String {
        let full = auth.profile?.full_name ?? ""
        return full.components(separatedBy: " ").first ?? "Paciente"
    }

    // MARK: Acesso Rápido
    private var quickAccess: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Serviços")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "101828"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ServiceCard(title: "Triagem",       icon: "waveform.path.ecg",          color: "2D8C82") { webURL = IdentifiableURL(KayaConfig.servicesURL) }
                ServiceCard(title: "Teleconsulta",  icon: "video.fill",                  color: "3B82F6") { webURL = IdentifiableURL(KayaConfig.teleconsultaURL) }
                ServiceCard(title: "Receitas",      icon: "pills.fill",                  color: "8B5CF6") { webURL = IdentifiableURL(KayaConfig.prescriptionURL) }
                ServiceCard(title: "Especialistas", icon: "stethoscope",                 color: "EF7C8E") { webURL = IdentifiableURL(KayaConfig.specialistsURL) }
                ServiceCard(title: "Medições",      icon: "heart.text.square.fill",      color: "F59E0B") { /* scroll */ }
                ServiceCard(title: "Criar conta",   icon: "person.badge.plus",           color: "667085") { webURL = IdentifiableURL(KayaConfig.registerURL) }
            }
        }
    }

    // MARK: Medições
    private var sectionReadings: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Minhas Medições", icon: "waveform.path.ecg", color: "2D8C82")
            VStack(spacing: 10) {
                ForEach(vm.readings.prefix(4)) { ReadingRow(reading: $0) }
            }
        }
    }

    // MARK: Medicação
    private var sectionMedications: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Medicação", icon: "pills.fill", color: "8B5CF6")
            VStack(spacing: 10) {
                ForEach(vm.medications.prefix(4)) { MedicationRow(med: $0) }
            }
        }
    }

    // MARK: Notificações
    private var sectionNotifications: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notificações", icon: "bell.fill", color: "F59E0B")
            if vm.isLoading {
                ProgressCard()
            } else if vm.notifications.isEmpty {
                EmptyCard(message: "Sem notificações.", icon: "bell.slash")
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.notifications.prefix(5)) { NotificationRow(notif: $0) }
                }
            }
        }
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

// MARK: - Service WebView Sheet
struct ServiceWebView: View, Identifiable {
    let url: URL
    var id: String { url.absoluteString }
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SimpleWebView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(url.host ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } }
                }
        }
    }
}

struct SimpleWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        wv.load(URLRequest(url: url))
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}


// MARK: - Identifiable URL wrapper
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
    init(_ url: URL) { self.url = url }
}

// MARK: - ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var readings:      [DeviceReadingItem] = []
    @Published var medications:   [MedicationItem]    = []
    @Published var notifications: [NotifItem]         = []
    @Published var isLoading = false

    private let base = KayaConfig.baseAPI

    func load(token: String) async {
        isLoading = true
        defer { isLoading = false }
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
        if let r = await get("/api/v1/readings/me", token: token, as: ReadingsResponse.self) {
            readings = r.readings
        }
    }
    private func fetchMeds(token: String) async {
        if let m = await get("/api/v1/medications/me", token: token, as: [MedicationItem].self) {
            medications = m
        }
    }
    private func fetchNotifs(token: String) async {
        if let n = await get("/api/v1/notifications/me", token: token, as: [NotifItem].self) {
            notifications = n
        }
    }
}

// MARK: - Models
struct ReadingsResponse: Decodable { let readings: [DeviceReadingItem]; let total: Int? }
struct DeviceReadingItem: Identifiable, Decodable { let id: String; let reading_type: String; let value: Double; let unit: String?; let measured_at: String? }
struct MedicationItem: Identifiable, Decodable { let id: String; let medication_name: String; let dosage: String?; let frequency: String?; let is_active: Bool? }
struct NotifItem: Identifiable, Decodable { let id: String; let title: String?; let message: String?; let is_read: Bool? }

// MARK: - Reusable Sub-views
private struct SectionHeader: View {
    let title: String; let icon: String; let color: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: color))
            Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(Color(hex: "101828"))
        }
    }
}

private struct ServiceCard: View {
    let title: String; let icon: String; let color: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Color(hex: color).opacity(0.12)).frame(width: 52, height: 52)
                    Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundStyle(Color(hex: color))
                }
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: "344054")).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

private struct ProgressCard: View {
    var body: some View {
        HStack { Spacer(); ProgressView(); Spacer() }.padding(20).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct EmptyCard: View {
    let message: String; let icon: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Color(hex: "A0AEC0"))
            Text(message).font(.system(size: 14, weight: .medium)).foregroundStyle(Color(hex: "667085"))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct ReadingRow: View {
    let reading: DeviceReadingItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                if let d = reading.measured_at { Text(fmt(d)).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
            }
            Spacer()
            Text("\(String(format: reading.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", reading.value)) \(reading.unit ?? "")")
                .font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: "101828"))
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    private var icon: String {
        switch reading.reading_type.lowercased() {
        case "blood_pressure": return "heart.fill"
        case "glucose":        return "drop.fill"
        case "temperature":    return "thermometer"
        case "weight":         return "scalemass.fill"
        default:               return "waveform.path.ecg"
        }
    }
    private var color: Color {
        switch reading.reading_type.lowercased() {
        case "blood_pressure": return Color(hex: "EF4444")
        case "glucose":        return Color(hex: "F59E0B")
        case "temperature":    return Color(hex: "3B82F6")
        case "weight":         return Color(hex: "8B5CF6")
        default:               return Color(hex: "2D8C82")
        }
    }
    private var label: String {
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
                if let d = med.dosage { Text("\(d)\(med.frequency.map { " · \($0)" } ?? "")").font(.system(size: 12)).foregroundStyle(Color(hex: "667085")) }
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

// MARK: - WKWebView import
import WebKit
