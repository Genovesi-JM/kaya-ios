import SwiftUI
import WebKit

// MARK: - Patient Dashboard (nativo — sem WebView, sem redirects)
struct PatientDashboardView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var vm   = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if auth.isLoggedIn {
            nativeDashboard
        } else {
            NativeLoginForm()
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var nativeDashboard: some View {
        ZStack(alignment: .top) {
            Color(hex: "F7FAFC").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 60) // espaço para topBar

                    // Hero
                    heroCard

                    // Medições
                    sectionReadings

                    // Medicação
                    sectionMedications

                    // Notificações
                    sectionNotifications

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
            }

            // Barra nativa fixa
            VStack(spacing: 0) {
                topBar
                Divider().opacity(0.3)
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await vm.load(token: auth.token() ?? "") }
        .refreshable { await vm.load(token: auth.token() ?? "") }
    }

    // MARK: Top Bar
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Text("Fechar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "2D8C82"))
            }
            .frame(width: 80, alignment: .leading)
            .padding(.leading, 16)

            Spacer()
            Text("Painel")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "101828"))
            Spacer()

            Button { auth.logout(); dismiss() } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "EF4444"))
            }
            .frame(width: 80, alignment: .trailing)
            .padding(.trailing, 16)
        }
        .frame(height: 52)
        .background(.ultraThinMaterial)
    }

    // MARK: Hero
    private var heroCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(hex: "2D8C82").opacity(0.18))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(auth.profile?.full_name?.prefix(1) ?? auth.profile?.email?.prefix(1) ?? "?").uppercased())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(hex: "2D8C82"))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("Olá, \(auth.profile?.full_name ?? "Paciente") 👋")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("O teu assistente de saúde digital.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(colors: [Color(hex: "2D8C82"), Color(hex: "1B6B62")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "2D8C82").opacity(0.3), radius: 12, x: 0, y: 6)
    }

    // MARK: Medições
    private var sectionReadings: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Minhas Medições", icon: "waveform.path.ecg")

            if vm.isLoadingReadings {
                ProgressCard()
            } else if vm.readings.isEmpty {
                EmptyCard(message: "Sem medições registadas.", icon: "heart.text.square")
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.readings.prefix(4)) { r in
                        ReadingRow(reading: r)
                    }
                }
            }
        }
    }

    // MARK: Medicação
    private var sectionMedications: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Medicação", icon: "pills.fill")

            if vm.isLoadingMeds {
                ProgressCard()
            } else if vm.medications.isEmpty {
                EmptyCard(message: "Sem medicação registada.", icon: "pills")
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.medications.prefix(4)) { m in
                        MedicationRow(med: m)
                    }
                }
            }
        }
    }

    // MARK: Notificações
    private var sectionNotifications: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notificações", icon: "bell.fill")

            if vm.notifications.isEmpty {
                EmptyCard(message: "Sem notificações.", icon: "bell.slash")
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.notifications.prefix(3)) { n in
                        NotificationRow(notif: n)
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var readings: [DeviceReadingItem] = []
    @Published var medications: [MedicationItem]  = []
    @Published var notifications: [NotifItem]      = []
    @Published var isLoadingReadings = false
    @Published var isLoadingMeds     = false

    private let base = "https://health.geovisionops.com"

    func load(token: String) async {
        async let r: Void = fetchReadings(token: token)
        async let m: Void = fetchMeds(token: token)
        async let n: Void = fetchNotifs(token: token)
        _ = await (r, m, n)
    }

    private func fetchReadings(token: String) async {
        isLoadingReadings = true
        defer { isLoadingReadings = false }
        guard let url = URL(string: "\(base)/api/v1/readings/me") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(ReadingsResponse.self, from: data) else { return }
        readings = decoded.readings
    }

    private func fetchMeds(token: String) async {
        isLoadingMeds = true
        defer { isLoadingMeds = false }
        guard let url = URL(string: "\(base)/api/v1/medications/me") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode([MedicationItem].self, from: data) else { return }
        medications = decoded
    }

    private func fetchNotifs(token: String) async {
        guard let url = URL(string: "\(base)/api/v1/notifications/me") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode([NotifItem].self, from: data) else { return }
        notifications = decoded
    }
}

// MARK: - Models
struct ReadingsResponse: Decodable {
    let readings: [DeviceReadingItem]
    let total: Int?
}

struct DeviceReadingItem: Identifiable, Decodable {
    let id: String
    let reading_type: String
    let value: Double
    let unit: String?
    let measured_at: String?
}

struct MedicationItem: Identifiable, Decodable {
    let id: String
    let medication_name: String
    let dosage: String?
    let frequency: String?
    let is_active: Bool?
}

struct NotifItem: Identifiable, Decodable {
    let id: String
    let title: String?
    let message: String?
    let is_read: Bool?
}

// MARK: - Sub-views
private struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "2D8C82"))
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "101828"))
        }
    }
}

private struct ProgressCard: View {
    var body: some View {
        HStack { Spacer(); ProgressView(); Spacer() }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct EmptyCard: View {
    let message: String
    let icon: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "A0AEC0"))
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "667085"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct ReadingRow: View {
    let reading: DeviceReadingItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(typeColor(reading.reading_type).opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: typeIcon(reading.reading_type))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(typeColor(reading.reading_type))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(typeLabel(reading.reading_type))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "101828"))
                if let d = reading.measured_at {
                    Text(formatDate(d))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "667085"))
                }
            }
            Spacer()
            Text("\(String(format: reading.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", reading.value)) \(reading.unit ?? "")")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "101828"))
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    func typeIcon(_ t: String) -> String {
        switch t.lowercased() {
        case "blood_pressure", "pressao_arterial": return "heart.fill"
        case "glucose", "glicose":                 return "drop.fill"
        case "temperature", "temperatura":         return "thermometer"
        case "weight", "peso":                     return "scalemass.fill"
        case "heart_rate", "frequencia_cardiaca":  return "waveform.path.ecg"
        default:                                   return "chart.line.uptrend.xyaxis"
        }
    }
    func typeColor(_ t: String) -> Color {
        switch t.lowercased() {
        case "blood_pressure", "pressao_arterial": return Color(hex: "EF4444")
        case "glucose", "glicose":                 return Color(hex: "F59E0B")
        case "temperature", "temperatura":         return Color(hex: "3B82F6")
        case "weight", "peso":                     return Color(hex: "8B5CF6")
        default:                                   return Color(hex: "2D8C82")
        }
    }
    func typeLabel(_ t: String) -> String {
        switch t.lowercased() {
        case "blood_pressure":   return "Pressão Arterial"
        case "glucose":          return "Glicose"
        case "temperature":      return "Temperatura"
        case "weight":           return "Peso"
        case "heart_rate":       return "Freq. Cardíaca"
        default:                 return t.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    func formatDate(_ s: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let d = f.date(from: s) else { return s }
        let out = DateFormatter()
        out.dateFormat = "dd MMM yyyy, HH:mm"
        out.locale = Locale(identifier: "pt_PT")
        return out.string(from: d)
    }
}

private struct MedicationRow: View {
    let med: MedicationItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "8B5CF6").opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: "pills.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "8B5CF6"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(med.medication_name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "101828"))
                if let d = med.dosage, let f = med.frequency {
                    Text("\(d) · \(f)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "667085"))
                }
            }
            Spacer()
            if med.is_active == true {
                Text("Activo").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "2D8C82"))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(hex: "2D8C82").opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct NotificationRow: View {
    let notif: NotifItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "F59E0B").opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: notif.is_read == true ? "bell" : "bell.badge.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "F59E0B"))
            }
            VStack(alignment: .leading, spacing: 2) {
                if let t = notif.title {
                    Text(t).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                }
                if let m = notif.message {
                    Text(m).font(.system(size: 12)).foregroundStyle(Color(hex: "667085")).lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Native Login Form
struct NativeLoginForm: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var email    = ""
    @State private var password = ""
    @State private var showDashboard = false
    @FocusState private var focus: Field?
    enum Field { case email, password }

    var body: some View {
        ZStack {
            Color(hex: "F7FAFC").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(hex: "667085"))
                                .frame(width: 36, height: 36)
                                .background(Color(hex: "F2F4F7"))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }.padding(.top, 8)

                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [Color(hex: "2D8C82"), Color(hex: "55B7A8")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                            .overlay(Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 36, weight: .bold)).foregroundStyle(.white))
                            .shadow(color: Color(hex: "2D8C82").opacity(0.3), radius: 16, x: 0, y: 8)
                        Text("KAYA Health").font(.system(size: 26, weight: .heavy)).foregroundStyle(Color(hex: "101828"))
                        Text("Entra com a tua conta para ver o painel de saúde.")
                            .font(.system(size: 15)).foregroundStyle(Color(hex: "5D6B82")).multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Email").font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: "475467"))
                        TextField("email@exemplo.com", text: $email)
                            .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($focus, equals: .email).submitLabel(.next).onSubmit { focus = .password }
                            .loginFieldStyle()

                        Text("Palavra-passe").font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: "475467"))
                        SecureField("••••••••", text: $password)
                            .focused($focus, equals: .password).submitLabel(.go).onSubmit { loginAction() }
                            .loginFieldStyle()

                        if let err = auth.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(err)
                            }
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(.red)
                            .padding(12).background(Color.red.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(18).background(.white).clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)

                    Button { loginAction() } label: {
                        Group {
                            if auth.isLoading { ProgressView().tint(.white) }
                            else { Label("Entrar no painel", systemImage: "arrow.right.circle.fill").font(.system(size: 16, weight: .bold)) }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(canSubmit ? Color(hex: "2D8C82") : Color(hex: "A0C8C2"))
                        .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 6)
                    }
                    .disabled(!canSubmit || auth.isLoading)
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
        .fullScreenCover(isPresented: $showDashboard) { PatientDashboardView() }
        .onChange(of: auth.isLoggedIn) { if $0 { showDashboard = true } }
    }

    private var canSubmit: Bool { !email.isEmpty && password.count >= 4 }
    private func loginAction() {
        focus = nil
        guard canSubmit else { return }
        Task { await auth.login(email: email, password: password) }
    }
}

private extension View {
    func loginFieldStyle() -> some View {
        self.padding(14).background(Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "D0D5DD"), lineWidth: 1))
    }
}
