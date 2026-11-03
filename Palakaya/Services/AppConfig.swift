import Foundation

/// Reads Supabase settings from Config/Secrets.plist (git-ignored).
/// Without that file the app keeps working fully offline.
enum AppConfig {
    private static let values: [String: String] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        else { return [:] }
        return dict
    }()

    static var supabaseURL: URL? {
        guard let raw = values["SUPABASE_URL"], !raw.contains("YOUR-PROJECT") else { return nil }
        return URL(string: raw)
    }

    static var supabaseAnonKey: String? {
        guard let key = values["SUPABASE_ANON_KEY"], !key.hasPrefix("YOUR-") else { return nil }
        return key
    }

    static var isCloudEnabled: Bool { supabaseURL != nil && supabaseAnonKey != nil }
}
