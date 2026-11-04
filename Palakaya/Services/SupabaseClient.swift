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
    private(set) var userID: String? = KeychainStore.get("user_id")

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

    /// Changes the cloud password of the signed-in account.
    func updatePassword(_ password: String) async throws {
        do {
            _ = try await request("auth/v1/user", method: "PUT", body: ["password": password])
        } catch CloudError.server(401, _) {
            try await refresh()
            _ = try await request("auth/v1/user", method: "PUT", body: ["password": password])
        }
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
        userID = nil
        KeychainStore.set(nil, for: "user_id")
        KeychainStore.set(nil, for: "access_token")
        KeychainStore.set(nil, for: "refresh_token")
    }

    private func refresh() async throws {
        guard let refreshToken else { throw CloudError.notSignedIn }
        let body = ["refresh_token": refreshToken]
        try await storeSession(from: request("auth/v1/token?grant_type=refresh_token", method: "POST", body: body, authorized: false))
    }

    private func storeSession(from data: Data) throws {
        struct User: Decodable { let id: String }
        struct Session: Decodable { let access_token: String?; let refresh_token: String?; let user: User? }
        let s = try JSONDecoder().decode(Session.self, from: data)
        guard let access = s.access_token else { throw CloudError.notSignedIn }
        accessToken = access
        refreshToken = s.refresh_token
        KeychainStore.set(access, for: "access_token")
        KeychainStore.set(s.refresh_token, for: "refresh_token")
        if let id = s.user?.id {
            userID = id
            KeychainStore.set(id, for: "user_id")
        }
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

    /// Updates the rows matching `filter` (PostgREST syntax, e.g. "id=eq.<uuid>").
    func update<T: Encodable>(_ table: String, filter: String, values: T) async throws {
        let headers = ["Prefer": "return=minimal"]
        do {
            _ = try await request("rest/v1/\(table)?\(filter)", method: "PATCH", body: values, headers: headers)
        } catch CloudError.server(401, _) {
            try await refresh()
            _ = try await request("rest/v1/\(table)?\(filter)", method: "PATCH", body: values, headers: headers)
        }
    }

    /// Inserts one row without merging into existing ones.
    func insert<T: Encodable>(_ table: String, row: T) async throws {
        let headers = ["Prefer": "return=minimal"]
        do {
            _ = try await request("rest/v1/\(table)", method: "POST", body: row, headers: headers)
        } catch CloudError.server(401, _) {
            try await refresh()
            _ = try await request("rest/v1/\(table)", method: "POST", body: row, headers: headers)
        }
    }

    /// Uploads a JPEG to a public Storage bucket (replacing any file at that path) and returns its public URL.
    func uploadPublicJPEG(_ data: Data, bucket: String, path: String) async throws -> String {
        func send() async throws {
            guard let base = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey,
                  let url = URL(string: "storage/v1/object/\(bucket)/\(path)", relativeTo: base) else { throw CloudError.notConfigured }
            guard let accessToken else { throw CloudError.notSignedIn }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 60
            req.setValue(key, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            req.setValue("true", forHTTPHeaderField: "x-upsert")
            let (body, response) = try await session.upload(for: req, from: data)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else {
                throw CloudError.server(status, String(data: body, encoding: .utf8) ?? "")
            }
        }
        do { try await send() } catch CloudError.server(401, _) { try await refresh(); try await send() }
        guard let base = AppConfig.supabaseURL else { throw CloudError.notConfigured }
        return base.appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)").absoluteString
    }

    /// A catch photo's address. Seeded demo photos store only their path in the `catch-photos` bucket.
    static func publicPhotoURL(_ stored: String?) -> URL? {
        guard let stored, !stored.isEmpty else { return nil }
        if stored.hasPrefix("http") { return URL(string: stored) }
        return AppConfig.supabaseURL?.appendingPathComponent("storage/v1/object/public/catch-photos/\(stored)")
    }

    /// Deletes one row by id (Row Level Security still applies).
    func delete(_ table: String, id: UUID) async throws {
        let path = "rest/v1/\(table)?id=eq.\(id.uuidString.lowercased())"
        do {
            _ = try await request(path, method: "DELETE", body: [String: String]())
        } catch CloudError.server(401, _) {
            try await refresh()
            _ = try await request(path, method: "DELETE", body: [String: String]())
        }
    }

    /// Calls a Supabase Edge Function as the signed-in user and returns its JSON body.
    func invoke<B: Encodable>(function name: String, body: B) async throws -> Data {
        do {
            return try await request("functions/v1/\(name)", method: "POST", body: body)
        } catch CloudError.server(401, _) {
            try await refresh()
            return try await request("functions/v1/\(name)", method: "POST", body: body)
        }
    }

    /// Reads rows the signed-in user is allowed to see (Row Level Security applies).
    func select<T: Decodable>(_ table: String, query: String = "select=*") async throws -> [T] {
        let data: Data
        do {
            data = try await get("rest/v1/\(table)?\(query)")
        } catch CloudError.server(401, _) {
            try await refresh()
            data = try await get("rest/v1/\(table)?\(query)")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: raw) ?? ISO8601DateFormatter().date(from: raw) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date \(raw)"))
        }
        return try decoder.decode([T].self, from: data)
    }

    // MARK: Transport

    private func get(_ path: String) async throws -> Data {
        guard let base = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey,
              let url = URL(string: path, relativeTo: base) else { throw CloudError.notConfigured }
        guard let accessToken else { throw CloudError.notSignedIn }
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.setValue(key, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw CloudError.server(status, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    private func request<B: Encodable>(_ path: String, method: String, body: B,
                                       headers: [String: String] = [:], authorized: Bool = true) async throws -> Data {
        guard let base = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey,
              let url = URL(string: path, relativeTo: base) else { throw CloudError.notConfigured }
        var req = URLRequest(url: url)
        req.httpMethod = method
        // The free AI Advisor can take close to a minute, so allow more time than usual.
        req.timeoutInterval = path.hasPrefix("functions/") ? 90 : 60
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
