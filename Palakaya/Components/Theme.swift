import SwiftUI

// MARK: - Color palette (matches original design)

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

    static let pkDark = Color(hex: "085078")
    static let pkAqua = Color(hex: "85D8CE")
    static let pkNavy = Color(hex: "07344C")
    static let pkBg = Color(hex: "F5F8F8")
    static let pkSurface = Color.white
    static let pkSurface2 = Color(hex: "EDF7F6")
    static let pkText = Color(hex: "10272D")
    static let pkSub = Color(hex: "667A80")
    static let pkBorder = Color(hex: "DDE9E8")
    static let pkSuccess = Color(hex: "3E9C7D")
    static let pkSuccessBg = Color(hex: "E7F5EF")
    static let pkWarning = Color(hex: "C9852B")
    static let pkWarningBg = Color(hex: "FCF2E1")
    static let pkDanger = Color(hex: "C9483E")
    static let pkDangerBg = Color(hex: "FBEAE8")
    static let pkInfo = Color(hex: "1F6FA3")
    static let pkInfoBg = Color(hex: "E7F1F7")
}

extension LinearGradient {
    static let pkBrand = LinearGradient(colors: [Color.pkDark, Color.pkAqua], startPoint: .topLeading, endPoint: .bottomTrailing)
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
            .padding(.vertical, 14)
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
                .padding(.vertical, 14)
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
            .padding(.vertical, 14)
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
        .font(.system(size: 15))
        .padding(12)
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
            .background(Color.pkSurface)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pkBorder))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
