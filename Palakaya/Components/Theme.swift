import SwiftUI

// MARK: - Color palette (matches the Palakaya logo: ocean blue, navy, sea teal)

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// A color that follows the system appearance: `light` in Light Mode, `dark` in Dark Mode.
    init(light: String, dark: String) {
        let l = UIColor(Color(hex: light)), d = UIColor(Color(hex: dark))
        self.init(UIColor { $0.userInterfaceStyle == .dark ? d : l })
    }

    // Dark Mode uses a night-sea navy rather than black, so the brand blues still read as the ocean.
    static let pkDark = Color(light: "0261A7", dark: "3A93D6")
    static let pkAqua = Color(hex: "2ED5CC")
    static let pkNavy = Color(light: "01447E", dark: "0B4F8A")
    static let pkBg = Color(light: "F5F8F8", dark: "0A1A2B")
    static let pkSurface = Color(light: "FFFFFF", dark: "112638")
    static let pkSurface2 = Color(light: "EDF7F6", dark: "17324A")
    static let pkText = Color(light: "10272D", dark: "E8F1F5")
    static let pkSub = Color(light: "667A80", dark: "93A9B5")
    static let pkBorder = Color(light: "DDE9E8", dark: "223B52")
    static let pkSuccess = Color(light: "3E9C7D", dark: "4CC39A")
    static let pkSuccessBg = Color(light: "E7F5EF", dark: "123528")
    static let pkWarning = Color(light: "C9852B", dark: "E0A24A")
    static let pkWarningBg = Color(light: "FCF2E1", dark: "3A2A12")
    static let pkDanger = Color(light: "C9483E", dark: "EF6B60")
    static let pkDangerBg = Color(light: "FBEAE8", dark: "3D1A18")
    static let pkInfo = Color(light: "1F6FA3", dark: "5AA8DE")
    static let pkInfoBg = Color(light: "E7F1F7", dark: "122C40")
}

extension LinearGradient {
    static let pkBrand = LinearGradient(colors: [Color.pkDark, Color.pkNavy], startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Tone (badges / status boxes)

enum Tone {
    case success, warning, danger, info

    var fg: Color {
        switch self {
        case .success: return .pkSuccess
        case .warning: return .pkWarning
        case .danger: return .pkDanger
        case .info: return .pkInfo
        }
    }
    var bg: Color {
        switch self {
        case .success: return .pkSuccessBg
        case .warning: return .pkWarningBg
        case .danger: return .pkDangerBg
        case .info: return .pkInfoBg
        }
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var full: Bool = true
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: full ? .infinity : nil)
            .frame(minHeight: 52)
            .padding(.horizontal, full ? 0 : 22)
            .background(Color.pkDark)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isDisabled ? 0.4 : 1)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}

struct GradientButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(LinearGradient.pkBrand)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.pkDark.opacity(0.18), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct GhostButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Color.pkSurface)
            .foregroundColor(.pkDark)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pkBorder))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small shared components

struct Badge: View {
    var tone: Tone
    var text: String
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 10, weight: .bold)) }
            Text(text)
        }
        .font(.system(size: 11, weight: .semibold))
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(tone.bg)
        .foregroundColor(tone.fg)
        .clipShape(Capsule())
    }
}

struct LabelCaps: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundColor(.pkSub)
            .tracking(0.3)
    }
}

struct SectionHeading: View {
    var title: String
    var actionText: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(.pkText)
            Spacer()
            if let actionText, let action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionText)
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.pkDark)
                }
            }
        }
        .padding(.vertical, 12)
    }
}

struct FieldLabel: ViewModifier {
    var label: String
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(.pkSub)
            content
        }
        .padding(.bottom, 16)
    }
}
extension View {
    func pkField(_ label: String) -> some View { modifier(FieldLabel(label: label)) }
}

struct PKTextField: View {
    var placeholder: String = ""
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
            }
        }
        .font(.system(size: 16))
        .padding(12)
        .frame(minHeight: 48)
        .background(Color.pkSurface)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct InfoBox: View {
    var text: String
    var light: Bool = false
    var extra: String? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle").foregroundColor(light ? .pkDark : .pkInfo)
            VStack(alignment: .leading, spacing: 4) {
                Text(text).font(.system(size: 12)).foregroundColor(light ? .pkText : .pkInfo)
                    .fixedSize(horizontal: false, vertical: true)
                if let extra {
                    Text(extra).font(.system(size: 11.5, weight: .semibold)).foregroundColor(.pkDark)
                }
            }
        }
        .padding(14)
        .background(light ? Color.pkSurface2 : Color.pkInfoBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct EmptyStateView: View {
    var title: String
    var cta: String
    var action: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.pkSurface2).frame(width: 80, height: 80)
                Image(systemName: "scalemass").font(.system(size: 28)).foregroundColor(.pkDark)
            }
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.pkText)
            PrimaryButton(title: cta, full: false, action: action)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 52)
    }
}

struct StatBox: View {
    var label: String
    var value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 13)).foregroundColor(.pkSub)
            Text(value).font(.system(size: 17, weight: .bold)).foregroundColor(.pkText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CardContainer<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.pkSurface)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
