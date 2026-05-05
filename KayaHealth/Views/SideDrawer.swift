import SwiftUI

// MARK: - Language Manager

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @AppStorage("kaya_lang") var lang: String = "pt" {
        willSet { objectWillChange.send() }
    }
    private init() {}

    func t(_ key: String) -> String {
        return translations[key]?[lang] ?? translations[key]?["pt"] ?? key
    }
}

// MARK: - Translations Dictionary (PT / EN / FR / ES)

private let translations: [String: [String: String]] = [
    // Sidebar sections
    "sidebar.principal":     ["pt": "Principal",           "en": "Main",               "fr": "Principal",        "es": "Principal"],
    "sidebar.health":        ["pt": "Saúde & Dispositivos","en": "Health & Devices",   "fr": "Santé & Appareils","es": "Salud & Dispositivos"],
    "sidebar.plan":          ["pt": "Plano & Faturação",   "en": "Plan & Billing",     "fr": "Forfait & Facturation","es": "Plan & Facturación"],
    "sidebar.account":       ["pt": "Conta",               "en": "Account",            "fr": "Compte",           "es": "Cuenta"],
    // Sidebar links
    "sidebar.dashboard":     ["pt": "Dashboard",           "en": "Dashboard",          "fr": "Tableau de Bord",  "es": "Panel"],
    "sidebar.profile":       ["pt": "Perfil",              "en": "Profile",            "fr": "Profil",           "es": "Perfil"],
    "sidebar.triage":        ["pt": "Triagem",             "en": "Triage",             "fr": "Triage",           "es": "Triaje"],
    "sidebar.consultations": ["pt": "Consultas",           "en": "Consultations",      "fr": "Consultations",    "es": "Consultas"],
    "sidebar.selfcare":      ["pt": "Auto-Cuidado",        "en": "Self-Care",          "fr": "Auto-soins",       "es": "Autocuidado"],
    "sidebar.consents":      ["pt": "Consentimentos",      "en": "Consents",           "fr": "Consentements",    "es": "Consentimientos"],
    "sidebar.readings":      ["pt": "Medições",            "en": "Readings",           "fr": "Mesures",          "es": "Mediciones"],
    "sidebar.devices":       ["pt": "Dispositivos",        "en": "Devices",            "fr": "Appareils",        "es": "Dispositivos"],
    "sidebar.family":        ["pt": "Família",             "en": "Family",             "fr": "Famille",          "es": "Familia"],
    "sidebar.notifications": ["pt": "Alertas",             "en": "Alerts",             "fr": "Alertes",          "es": "Alertas"],
    "sidebar.pricing":       ["pt": "Subscrição",          "en": "Subscription",       "fr": "Abonnement",       "es": "Suscripción"],
    "sidebar.settings":      ["pt": "Definições",          "en": "Settings",           "fr": "Paramètres",       "es": "Ajustes"],
    "sidebar.logout":        ["pt": "Terminar Sessão",     "en": "Sign Out",           "fr": "Se Déconnecter",   "es": "Cerrar Sesión"],
    "sidebar.language":      ["pt": "Idioma",              "en": "Language",           "fr": "Langue",           "es": "Idioma"],
    // General
    "common.loading":        ["pt": "A carregar...",       "en": "Loading...",         "fr": "Chargement...",    "es": "Cargando..."],
    "common.error":          ["pt": "Erro",                "en": "Error",              "fr": "Erreur",           "es": "Error"],
    "common.save":           ["pt": "Guardar",             "en": "Save",               "fr": "Enregistrer",      "es": "Guardar"],
    "common.cancel":         ["pt": "Cancelar",            "en": "Cancel",             "fr": "Annuler",          "es": "Cancelar"],
    // Dashboard
    "dash.welcome":          ["pt": "Bem-vindo",           "en": "Welcome",            "fr": "Bienvenue",        "es": "Bienvenido"],
    "dash.health_panel":     ["pt": "O teu painel de saúde está atualizado.", "en": "Your health panel is up to date.", "fr": "Votre tableau de santé est à jour.", "es": "Tu panel de salud está actualizado."],
    "dash.loading":          ["pt": "A carregar o teu painel…", "en": "Loading your dashboard…", "fr": "Chargement de votre tableau…", "es": "Cargando tu panel…"],
    // Self-care
    "selfcare.title":        ["pt": "Autocuidado",         "en": "Self-Care",          "fr": "Auto-soins",       "es": "Autocuidado"],
    "selfcare.subtitle":     ["pt": "Recomendações para o seu bem-estar", "en": "Recommendations for your well-being", "fr": "Recommandations pour votre bien-être", "es": "Recomendaciones para tu bienestar"],
    "selfcare.tip_hydration":["pt": "Mantenha-se hidratado(a)", "en": "Stay hydrated", "fr": "Restez hydraté(e)", "es": "Mantente hidratado/a"],
    "selfcare.tip_hydration_desc": ["pt": "Beba pelo menos 2L de água por dia.", "en": "Drink at least 2L of water per day.", "fr": "Buvez au moins 2L d'eau par jour.", "es": "Bebe al menos 2L de agua al día."],
    "selfcare.tip_rest":     ["pt": "Descanse adequadamente", "en": "Rest adequately", "fr": "Reposez-vous adéquatement", "es": "Descansa adecuadamente"],
    "selfcare.tip_rest_desc":["pt": "Durma 7-9 horas por noite.", "en": "Sleep 7-9 hours per night.", "fr": "Dormez 7 à 9 heures par nuit.", "es": "Duerme 7-9 horas por noche."],
    "selfcare.tip_monitor":  ["pt": "Monitorize os sintomas", "en": "Monitor your symptoms", "fr": "Surveillez vos symptômes", "es": "Monitoriza los síntomas"],
    "selfcare.tip_monitor_desc": ["pt": "Se os sintomas piorarem, realize nova triagem.", "en": "If symptoms worsen, perform a new triage.", "fr": "Si les symptômes s'aggravent, effectuez un nouveau triage.", "es": "Si los síntomas empeoran, realiza un nuevo triaje."],
    "selfcare.tip_diet":     ["pt": "Alimentação equilibrada", "en": "Balanced diet", "fr": "Alimentation équilibrée", "es": "Alimentación equilibrada"],
    "selfcare.tip_diet_desc":["pt": "Prefira alimentos leves e nutritivos.", "en": "Prefer light and nutritious foods.", "fr": "Préférez des aliments légers et nutritifs.", "es": "Prefiere alimentos ligeros y nutritivos."],
    "selfcare.tip_exercise": ["pt": "Atividade física moderada", "en": "Moderate physical activity", "fr": "Activité physique modérée", "es": "Actividad física moderada"],
    "selfcare.tip_exercise_desc": ["pt": "Caminhe ou faça exercício leve.", "en": "Walk or do light exercise.", "fr": "Marchez ou faites de l'exercice léger.", "es": "Camina o haz ejercicio ligero."],
    "selfcare.when_seek":    ["pt": "Quando procurar ajuda médica", "en": "When to seek medical help", "fr": "Quand consulter un médecin", "es": "Cuándo buscar ayuda médica"],
    // Consents
    "consents.title":        ["pt": "Consentimentos",      "en": "Consents",           "fr": "Consentements",    "es": "Consentimientos"],
    "consents.subtitle":     ["pt": "Gerir autorizações de saúde", "en": "Manage your health authorizations", "fr": "Gérer vos autorisations", "es": "Gestionar autorizaciones de salud"],
    "consents.type_data":    ["pt": "Partilha de Dados Clínicos", "en": "Clinical Data Sharing", "fr": "Partage de Données Cliniques", "es": "Compartición de Datos Clínicos"],
    "consents.type_teleconsult": ["pt": "Teleconsulta", "en": "Teleconsultation", "fr": "Téléconsultation", "es": "Teleconsulta"],
    "consents.type_prescription": ["pt": "Prescrição Digital", "en": "Digital Prescription", "fr": "Prescription Numérique", "es": "Receta Digital"],
    "consents.type_notifications": ["pt": "Notificações de Saúde", "en": "Health Notifications", "fr": "Notifications de Santé", "es": "Notificaciones de Salud"],
    "consents.type_research": ["pt": "Investigação Clínica", "en": "Clinical Research", "fr": "Recherche Clinique", "es": "Investigación Clínica"],
    "consents.active":       ["pt": "Consentimentos Ativos", "en": "Active Consents", "fr": "Consentements Actifs", "es": "Consentimientos Activos"],
    "consents.none":         ["pt": "Sem consentimentos", "en": "No consents", "fr": "Aucun consentement", "es": "Sin consentimientos"],
    "consents.accept":       ["pt": "Aceitar", "en": "Accept", "fr": "Accepter", "es": "Aceptar"],
    // Family
    "family.title":          ["pt": "Família",             "en": "Family",             "fr": "Famille",          "es": "Familia"],
    "family.subtitle":       ["pt": "Perfis de menores e dependentes", "en": "Profiles for minors and dependents", "fr": "Profils des mineurs et dépendants", "es": "Perfiles de menores y dependientes"],
    "family.add":            ["pt": "Adicionar Familiar",  "en": "Add Family Member",  "fr": "Ajouter Membre",   "es": "Añadir Familiar"],
    "family.none":           ["pt": "Nenhum perfil familiar.", "en": "No family profiles.", "fr": "Aucun profil familial.", "es": "Ningún perfil familiar."],
    // Settings
    "settings.title":        ["pt": "Definições",          "en": "Settings",           "fr": "Paramètres",       "es": "Ajustes"],
    "settings.change_pw":    ["pt": "Alterar Palavra-passe","en": "Change Password",    "fr": "Changer le Mot de Passe","es": "Cambiar Contraseña"],
    "settings.current_pw":   ["pt": "Palavra-passe atual", "en": "Current password",   "fr": "Mot de passe actuel","es": "Contraseña actual"],
    "settings.new_pw":       ["pt": "Nova palavra-passe",  "en": "New password",       "fr": "Nouveau mot de passe","es": "Nueva contraseña"],
    "settings.confirm_pw":   ["pt": "Confirmar nova palavra-passe","en": "Confirm new password","fr": "Confirmer le nouveau mot de passe","es": "Confirmar nueva contraseña"],
    "settings.pw_submit":    ["pt": "Alterar",             "en": "Change",             "fr": "Modifier",         "es": "Cambiar"],
    "settings.pw_mismatch":  ["pt": "As palavras-passe não coincidem.", "en": "Passwords do not match.", "fr": "Les mots de passe ne correspondent pas.", "es": "Las contraseñas no coinciden."],
    "settings.pw_success":   ["pt": "Palavra-passe alterada.", "en": "Password changed.", "fr": "Mot de passe modifié.", "es": "Contraseña cambiada."],
    // Pricing
    "pricing.title":         ["pt": "Subscrição",          "en": "Subscription",       "fr": "Abonnement",       "es": "Suscripción"],
    "pricing.free":          ["pt": "Gratuito",            "en": "Free",               "fr": "Gratuit",          "es": "Gratuito"],
    "pricing.pro":           ["pt": "Pro",                 "en": "Pro",                "fr": "Pro",              "es": "Pro"],
    "pricing.current":       ["pt": "Plano Atual",         "en": "Current Plan",       "fr": "Forfait Actuel",   "es": "Plan Actual"],
    // Readings
    "readings.title":        ["pt": "Medições",            "en": "Readings",           "fr": "Mesures",          "es": "Mediciones"],
    "readings.add":          ["pt": "Adicionar Medição",   "en": "Add Reading",        "fr": "Ajouter Mesure",   "es": "Añadir Medición"],
    "readings.bp":           ["pt": "Pressão Arterial",    "en": "Blood Pressure",     "fr": "Pression Artérielle","es": "Presión Arterial"],
    "readings.glucose":      ["pt": "Glicose",             "en": "Glucose",            "fr": "Glycémie",         "es": "Glucosa"],
    "readings.temp":         ["pt": "Temperatura",         "en": "Temperature",        "fr": "Température",      "es": "Temperatura"],
    "readings.spo2":         ["pt": "Saturação O₂",        "en": "O₂ Saturation",      "fr": "Saturation O₂",    "es": "Saturación O₂"],
    "readings.weight":       ["pt": "Peso",                "en": "Weight",             "fr": "Poids",            "es": "Peso"],
    "readings.heart_rate":   ["pt": "Freq. Cardíaca",      "en": "Heart Rate",         "fr": "Fréq. Cardiaque",  "es": "Frec. Cardíaca"],
    "readings.none":         ["pt": "Sem medições.", "en": "No readings.", "fr": "Aucune mesure.", "es": "Sin mediciones."],
]

// MARK: - Side Drawer View

struct SideDrawerView: View {
    @Binding var isOpen: Bool
    @StateObject private var lang = LanguageManager.shared
    @StateObject private var auth = AuthService.shared
    // Destinations
    var onDashboard:     () -> Void = {}
    var onProfile:       () -> Void = {}
    var onTriagem:       () -> Void = {}
    var onConsultas:     () -> Void = {}
    var onSelfCare:      () -> Void = {}
    var onConsents:      () -> Void = {}
    var onReadings:      () -> Void = {}
    var onFamily:        () -> Void = {}
    var onNotifications: () -> Void = {}
    var onPricing:       () -> Void = {}
    var onSettings:      () -> Void = {}

    private let drawerWidth: CGFloat = 300

    var body: some View {
        ZStack(alignment: .leading) {
            // Backdrop
            if isOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.28)) { isOpen = false } }
                    .transition(.opacity)
            }
            // Drawer panel
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    // Header — user card
                    drawerHeader
                    Divider()
                    // Scrollable sections
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            drawerSection(lang.t("sidebar.principal")) {
                                drawerLink("house.fill",         lang.t("sidebar.dashboard"))     { close(); onDashboard() }
                                drawerLink("person.fill",        lang.t("sidebar.profile"))       { close(); onProfile() }
                                drawerLink("stethoscope",        lang.t("sidebar.triage"))        { close(); onTriagem() }
                                drawerLink("calendar",           lang.t("sidebar.consultations")) { close(); onConsultas() }
                                drawerLink("heart.text.square",  lang.t("sidebar.selfcare"))      { close(); onSelfCare() }
                                drawerLink("checkmark.seal",     lang.t("sidebar.consents"))      { close(); onConsents() }
                            }
                            drawerSection(lang.t("sidebar.health")) {
                                drawerLink("waveform.path.ecg",  lang.t("sidebar.readings"))      { close(); onReadings() }
                                drawerLink("person.2.fill",      lang.t("sidebar.family"))        { close(); onFamily() }
                                drawerLink("bell.badge.fill",    lang.t("sidebar.notifications")) { close(); onNotifications() }
                            }
                            drawerSection(lang.t("sidebar.plan")) {
                                drawerLink("star.circle.fill",   lang.t("sidebar.pricing"))       { close(); onPricing() }
                            }
                            drawerSection(lang.t("sidebar.account")) {
                                drawerLink("gearshape.fill",     lang.t("sidebar.settings"))      { close(); onSettings() }
                                drawerLink("rectangle.portrait.and.arrow.right", lang.t("sidebar.logout"), destructive: true) {
                                    close(); auth.logout()
                                }
                            }
                            // Language switcher
                            languageSwitcher
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                        }
                    }
                }
                .frame(width: drawerWidth)
                .background(Color(hex: "FFFFFF"))
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 4, y: 0)

                Spacer()
            }
            .offset(x: isOpen ? 0 : -drawerWidth)
        }
        .animation(.easeInOut(duration: 0.28), value: isOpen)
    }

    private func close() {
        withAnimation(.easeInOut(duration: 0.28)) { isOpen = false }
    }

    // MARK: - Header
    private var drawerHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "2D8C82").opacity(0.15))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(initials)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: "2D8C82"))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(auth.profile?.full_name ?? auth.profile?.email ?? "Utilizador")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "101828"))
                    .lineLimit(1)
                Text("Paciente")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "667085"))
            }
            Spacer()
            Button { close() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "667085"))
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .padding(.top, 4)
    }

    private var initials: String {
        String(auth.profile?.full_name?.prefix(1) ?? auth.profile?.email?.prefix(1) ?? "?").uppercased()
    }

    // MARK: - Section Builder
    @ViewBuilder
    private func drawerSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 4)
            content()
        }
    }

    // MARK: - Link Row
    @ViewBuilder
    private func drawerLink(_ icon: String, _ label: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .frame(width: 22)
                    .foregroundStyle(destructive ? Color(hex: "EF4444") : Color(hex: "2D8C82"))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(destructive ? Color(hex: "EF4444") : Color(hex: "101828"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Language Switcher
    private var languageSwitcher: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lang.t("sidebar.language").uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .padding(.horizontal, 16)
                .padding(.top, 10)
            HStack(spacing: 8) {
                ForEach(["pt", "en", "fr", "es"], id: \.self) { code in
                    let flags = ["pt": "🇵🇹", "en": "🇬🇧", "fr": "🇫🇷", "es": "🇪🇸"]
                    let labels = ["pt": "PT", "en": "EN", "fr": "FR", "es": "ES"]
                    Button {
                        lang.lang = code
                    } label: {
                        VStack(spacing: 2) {
                            Text(flags[code] ?? "")
                                .font(.system(size: 18))
                            Text(labels[code] ?? code.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(lang.lang == code ? Color(hex: "2D8C82") : Color(hex: "667085"))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(lang.lang == code ? Color(hex: "2D8C82").opacity(0.12) : Color(hex: "F3F4F6"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(lang.lang == code ? Color(hex: "2D8C82") : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Self-Care View

struct SelfCareView: View {
    @StateObject private var lang = LanguageManager.shared

    private let tips: [(icon: String, key: String, descKey: String)] = [
        ("drop.fill",           "selfcare.tip_hydration", "selfcare.tip_hydration_desc"),
        ("moon.fill",           "selfcare.tip_rest",      "selfcare.tip_rest_desc"),
        ("waveform.path.ecg",   "selfcare.tip_monitor",   "selfcare.tip_monitor_desc"),
        ("fork.knife",          "selfcare.tip_diet",      "selfcare.tip_diet_desc"),
        ("figure.walk",         "selfcare.tip_exercise",  "selfcare.tip_exercise_desc"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Banner
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "22C55E"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Boa notícia!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "15803D"))
                        Text("A sua triagem indica risco baixo. Siga estas recomendações.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "166534"))
                    }
                }
                .padding(14)
                .background(Color(hex: "DCFCE7"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                // Tips
                VStack(spacing: 12) {
                    ForEach(tips, id: \.key) { tip in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: tip.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "2D8C82"))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lang.t(tip.key))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: "101828"))
                                Text(lang.t(tip.descKey))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "667085"))
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)

                // When to seek help
                VStack(alignment: .leading, spacing: 10) {
                    Label(lang.t("selfcare.when_seek"), systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "D97706"))
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(["Sintomas piorarem significativamente",
                                 "Surgirem novos sintomas preocupantes",
                                 "Febre superior a 38.5°C por mais de 48h",
                                 "Dificuldade em respirar ou dor intensa"], id: \.self) { item in
                            HStack(spacing: 8) {
                                Circle().fill(Color(hex: "D97706")).frame(width: 5, height: 5)
                                Text(item).font(.system(size: 13)).foregroundStyle(Color(hex: "667085"))
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(hex: "FFFBEB"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "FDE68A"), lineWidth: 1))
                .padding(.horizontal, 16)

                Spacer(minLength: 30)
            }
            .padding(.top, 16)
        }
        .background(Color(hex: "F5F7FA").ignoresSafeArea())
        .navigationTitle(lang.t("selfcare.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Consents View

struct ConsentView: View {
    @StateObject private var lang = LanguageManager.shared
    @StateObject private var auth = AuthService.shared
    @State private var consents: [ConsentItem] = []
    @State private var isLoading = false
    @State private var selectedType = "data_sharing"
    @State private var isAccepting = false
    @State private var successMsg = ""

    private let types = [
        ("data_sharing",   "consents.type_data"),
        ("teleconsult",    "consents.type_teleconsult"),
        ("prescription",   "consents.type_prescription"),
        ("notifications",  "consents.type_notifications"),
        ("research",       "consents.type_research"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Add new consent
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Novo Consentimento")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "101828"))
                        Picker("Tipo", selection: $selectedType) {
                            ForEach(types, id: \.0) { t in
                                Text(lang.t(t.1)).tag(t.0)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color(hex: "F9FAFB"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "E5E7EB"), lineWidth: 1))

                        if !successMsg.isEmpty {
                            Text(successMsg)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "22C55E"))
                        }

                        Button {
                            Task { await acceptConsent() }
                        } label: {
                            HStack {
                                Spacer()
                                if isAccepting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(lang.t("consents.accept"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            .frame(height: 42)
                            .background(Color(hex: "2D8C82"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(isAccepting)
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)

                    // Active consents
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang.t("consents.active"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "101828"))
                            .padding(.horizontal, 16)

                        if isLoading {
                            ProgressView().padding().frame(maxWidth: .infinity)
                        } else if consents.isEmpty {
                            Text(lang.t("consents.none"))
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "667085"))
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(consents) { c in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color(hex: "22C55E"))
                                        .font(.system(size: 16))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.consent_type.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color(hex: "101828"))
                                        if let at = c.accepted_at {
                                            Text("Aceite em \(formatDate(at))")
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color(hex: "9CA3AF"))
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "E5E7EB"), lineWidth: 1))
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
            .background(Color(hex: "F5F7FA").ignoresSafeArea())
            .navigationTitle(lang.t("consents.title"))
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadConsents() }
    }

    private func loadConsents() async {
        guard let token = auth.token() else { return }
        isLoading = true
        defer { isLoading = false }
        guard let url = URL(string: "\(KayaConfig.baseAPI)/api/v1/consents/") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let (data, _) = try? await URLSession.shared.data(for: req),
           let list = try? JSONDecoder().decode([ConsentItem].self, from: data) {
            consents = list
        }
    }

    private func acceptConsent() async {
        guard let token = auth.token() else { return }
        isAccepting = true
        defer { isAccepting = false }
        guard let url = URL(string: "\(KayaConfig.baseAPI)/api/v1/consents/") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["consent_type": selectedType])
        if let (_, resp) = try? await URLSession.shared.data(for: req),
           (resp as? HTTPURLResponse)?.statusCode == 201 || (resp as? HTTPURLResponse)?.statusCode == 200 {
            successMsg = "Consentimento registado."
            await loadConsents()
        }
    }

    private func formatDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        if let d = f.date(from: iso) {
            let df = DateFormatter()
            df.dateStyle = .short; df.timeStyle = .none
            return df.string(from: d)
        }
        return iso
    }
}

struct ConsentItem: Identifiable, Decodable {
    let id: Int
    let consent_type: String
    let accepted_at: String?
}

// MARK: - Family View

struct FamilyView: View {
    @StateObject private var lang = LanguageManager.shared
    @StateObject private var auth = AuthService.shared
    @State private var members: [FamilyMember] = []
    @State private var isLoading = false
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newDob = ""
    @State private var newRel = "son"
    @State private var isSaving = false

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    } else if members.isEmpty && !showAdd {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color(hex: "D1D5DB"))
                            Text(lang.t("family.none"))
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "667085"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        ForEach(members) { m in
                            HStack(spacing: 12) {
                                Circle().fill(Color(hex: "2D8C82").opacity(0.12)).frame(width: 40, height: 40)
                                    .overlay(Text(String(m.full_name.prefix(1)).uppercased()).font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: "2D8C82")))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(m.full_name).font(.system(size: 14, weight: .medium)).foregroundStyle(Color(hex: "101828"))
                                    Text(m.relationship ?? "").font(.system(size: 12)).foregroundStyle(Color(hex: "667085"))
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "E5E7EB"), lineWidth: 1))
                            .padding(.horizontal, 16)
                        }
                    }

                    if showAdd {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(lang.t("family.add")).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "101828"))
                            TextField(lang.t("family.name"), text: $newName)
                                .textFieldStyle(.roundedBorder)
                            TextField(lang.t("family.dob") + " (AAAA-MM-DD)", text: $newDob)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numbersAndPunctuation)
                            Picker(lang.t("family.rel"), selection: $newRel) {
                                Text(lang.t("family.rel_son")).tag("son")
                                Text(lang.t("family.rel_daughter")).tag("daughter")
                                Text(lang.t("family.rel_other")).tag("other")
                            }
                            .pickerStyle(.segmented)
                            HStack(spacing: 10) {
                                Button(lang.t("common.cancel")) { showAdd = false }
                                    .buttonStyle(.bordered)
                                Button {
                                    Task { await saveMember() }
                                } label: {
                                    if isSaving { ProgressView().tint(.white) }
                                    else { Text(lang.t("family.save")).foregroundStyle(.white) }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(Color(hex: "2D8C82"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .disabled(isSaving || newName.isEmpty)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 16)
                    }

                    if !showAdd {
                        Button {
                            showAdd = true
                        } label: {
                            Label(lang.t("family.add"), systemImage: "plus.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "2D8C82"))
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
            .background(Color(hex: "F5F7FA").ignoresSafeArea())
            .navigationTitle(lang.t("family.title"))
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadMembers() }
    }

    private func loadMembers() async {
        guard let token = auth.token() else { return }
        isLoading = true; defer { isLoading = false }
        guard let url = URL(string: "\(KayaConfig.baseAPI)/api/v1/family/") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let (data, _) = try? await URLSession.shared.data(for: req),
           let list = try? JSONDecoder().decode([FamilyMember].self, from: data) {
            members = list
        }
    }

    private func saveMember() async {
        guard let token = auth.token(), !newName.isEmpty else { return }
        isSaving = true; defer { isSaving = false }
        guard let url = URL(string: "\(KayaConfig.baseAPI)/api/v1/family/") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["full_name": newName, "relationship": newRel]
        if !newDob.isEmpty { body["date_of_birth"] = newDob }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        if let (_, resp) = try? await URLSession.shared.data(for: req),
           (resp as? HTTPURLResponse)?.statusCode ?? 0 < 300 {
            newName = ""; newDob = ""; showAdd = false
            await loadMembers()
        }
    }
}

struct FamilyMember: Identifiable, Decodable {
    let id: Int
    let full_name: String
    let relationship: String?
    let date_of_birth: String?
}

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var lang = LanguageManager.shared
    @StateObject private var auth = AuthService.shared
    @State private var currentPw = ""
    @State private var newPw = ""
    @State private var confirmPw = ""
    @State private var isChanging = false
    @State private var msg = ""
    @State private var msgOk = true

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Account info card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Informações da Conta")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "101828"))
                        infoRow(icon: "envelope.fill", label: "Email", value: auth.profile?.email ?? "—")
                        infoRow(icon: "person.fill", label: "Nome", value: auth.profile?.full_name ?? "—")
                        infoRow(icon: "shield.fill", label: "Função", value: "Paciente")
                        Text("Para alterar estas informações, contacte o suporte.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)

                    // Change password
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.t("settings.change_pw"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "101828"))

                        SecureField(lang.t("settings.current_pw"), text: $currentPw)
                            .textFieldStyle(.roundedBorder)
                        SecureField(lang.t("settings.new_pw"), text: $newPw)
                            .textFieldStyle(.roundedBorder)
                        SecureField(lang.t("settings.confirm_pw"), text: $confirmPw)
                            .textFieldStyle(.roundedBorder)

                        if !msg.isEmpty {
                            Text(msg)
                                .font(.system(size: 13))
                                .foregroundStyle(msgOk ? Color(hex: "22C55E") : Color(hex: "EF4444"))
                        }

                        Button {
                            Task { await changePassword() }
                        } label: {
                            HStack {
                                Spacer()
                                if isChanging { ProgressView().tint(.white) }
                                else {
                                    Text(lang.t("settings.pw_submit"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            .frame(height: 42)
                            .background(Color(hex: "2D8C82"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(isChanging)
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
            .background(Color(hex: "F5F7FA").ignoresSafeArea())
            .navigationTitle(lang.t("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(Color(hex: "2D8C82")).frame(width: 18)
            Text(label).font(.system(size: 13)).foregroundStyle(Color(hex: "667085")).frame(width: 60, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .medium)).foregroundStyle(Color(hex: "101828"))
            Spacer()
        }
    }

    private func changePassword() async {
        guard !newPw.isEmpty else { return }
        if newPw != confirmPw { msg = lang.t("settings.pw_mismatch"); msgOk = false; return }
        if newPw.count < 6 { msg = "Mínimo 6 caracteres."; msgOk = false; return }
        guard let token = auth.token(),
              let url = URL(string: "\(KayaConfig.baseAPI)/api/v1/auth/change-password") else { return }
        isChanging = true; defer { isChanging = false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["current_password": currentPw, "new_password": newPw])
        if let (_, resp) = try? await URLSession.shared.data(for: req),
           (resp as? HTTPURLResponse)?.statusCode ?? 0 < 300 {
            msg = lang.t("settings.pw_success"); msgOk = true
            currentPw = ""; newPw = ""; confirmPw = ""
        } else {
            msg = "Erro ao alterar."; msgOk = false
        }
    }
}

// MARK: - Pricing View

struct PricingView: View {
    @StateObject private var lang = LanguageManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Free plan
                planCard(
                    title: "Gratuito",
                    subtitle: "Para sempre",
                    price: "0€",
                    features: ["Triagem inteligente", "Consultas básicas", "Perfil clínico", "Medições manuais"],
                    color: "6B7280",
                    current: true
                )
                // Pro plan
                planCard(
                    title: "Pro",
                    subtitle: "Por mês",
                    price: "9.99€",
                    features: ["Tudo no Gratuito", "Teleconsulta ilimitada", "Prescrições digitais", "Perfis familiares", "Dispositivos IoT", "Suporte prioritário"],
                    color: "2D8C82",
                    current: false
                )
                Text("Para gerir a sua subscrição, aceda ao portal web.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Spacer(minLength: 30)
            }
            .padding(.top, 20)
        }
        .background(Color(hex: "F5F7FA").ignoresSafeArea())
        .navigationTitle(lang.t("pricing.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func planCard(title: String, subtitle: String, price: String, features: [String], color: String, current: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: color))
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(Color(hex: "667085"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price).font(.system(size: 22, weight: .heavy)).foregroundStyle(Color(hex: color))
                    if current {
                        Text(lang.t("pricing.current"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: color))
                            .clipShape(Capsule())
                    }
                }
            }
            Divider()
            ForEach(features, id: \.self) { f in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: color)).font(.system(size: 14))
                    Text(f).font(.system(size: 13)).foregroundStyle(Color(hex: "374151"))
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(current ? Color(hex: color) : Color(hex: "E5E7EB"), lineWidth: current ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}
