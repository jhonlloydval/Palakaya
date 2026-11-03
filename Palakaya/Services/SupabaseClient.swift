import Foundation

enum CloudError: LocalizedError {
    case notConfigured
    case notSignedIn
    case server(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Cloud sync is not set up."
        case .notSignedIn: return "Not signed in to cloud sync."
        case .server(let code, let message): return "Cloud error \(code): \(message)"
        }
    }
}

/// Minimal Supabase REST client (Auth + PostgREST) using URLSession, so no package dependency is needed.
final class SupabaseClient {
    static let shared = SupabaseClient()

    private let session = URLSession.shared
    private(set) var accessToken: String? = KeychainStore.get("access_token")
    private var refreshToken: String? = KeychainStore.get("refresh_token")

    var isSignedIn: Bool { accessToken != nil }

    // MARK: Auth

    /// Supabase email auth needs an email, so the mobile number is mapped to a placeholder address.
    /// Turn off "Confirm email" in Supabase Auth settings, since these addresses cannot receive mail.
    private func authEmail(for mobile: String) -> String { "\(mobile)@palakaya.example.com" }

    func signUp(mobile: String, password: String) async throws {
        let body = ["email": authEmail(for: mobile), "password": password]
        try await storeSession(from: request("auth/v1/signup", method: "POST", body: body, authorized: false))
    }

    func signIn(mobile: String, password: String) async throws {
        let body = ["email": authEmail(for: mobile), "password": password]
        try await storeSession(from: request("auth/v1/token?grant_type=password", method: "POST", body: body, authorized: false))
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
        KeychainStore.set(nil, for: "access_token")
        KeychainStore.set(nil, for: "refresh_token")
    }

    private func refresh() async throws {
        guard let refreshToken else { throw CloudError.notSignedIn }
        let body = ["refresh_token": refreshToken]
        try await storeSession(from: request("auth/v1/token?grant_type=refresh_token", method: "POST", body: body, authorized: false))
    }

    private func storeSession(from data: Data) throws {
        struct Session: Decodable { let access_token: String?; let refresh_token: String? }
        let s = try JSONDecoder().decode(Session.self, from: data)
        guard let access = s.access_token else { throw CloudError.notSignedIn }
        accessToken = access
        refreshToken = s.refresh_token
        KeychainStore.set(access, for: "access_token")
        KeychainStore.set(s.refresh_token, for: "refresh_token")
    }

    // MARK: Data

    /// Inserts or updates rows (matched on primary key). Retries once after refreshing an expired token.
    func upsert<T: Encodable>(_ table: String, rows: [T]) async throws {
        guard !rows.isEmpty else { return }
        let headers = ["Prefer": "resolution=merge-duplicates,return=minimal"]
        do {
            _ = try await request("rest/v1/\(table)", method: "POST", body: rows, headers: headers)
        } catch CloudError.server(401, _) {
            try await refresh()
            _ = try await request("rest/v1/\(table)", method: "POST", body: rows, headers: headers)
        }
    }

    // MARK: Transport

    private func request<B: Encodable>(_ path: String, method: String, body: B,
                                       headers: [String: String] = [:], authorized: Bool = true) async throws -> Data {
        guard let base = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey,
              let url = URL(string: path, relativeTo: base) else { throw CloudError.notConfigured }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "apikey")
        if authorized {
            guard let accessToken else { throw CloudError.notSignedIn }
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        req.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw CloudError.server(status, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }
}
