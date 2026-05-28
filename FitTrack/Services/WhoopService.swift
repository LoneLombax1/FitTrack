import Foundation
import AuthenticationServices
import Security
import CommonCrypto

struct WhoopCycleResult {
    let recoveryScore: Int?
    let strainScore: Double?
}

struct WhoopWorkoutResult {
    let start: Date
    let end: Date
    let strain: Double?
    var durationMinutes: Int { max(1, Int(end.timeIntervalSince(start) / 60)) }
}

@MainActor
final class WhoopService: NSObject, ObservableObject {

    static let shared = WhoopService()

    private let clientId     = Config.whoopClientId
    private let clientSecret = Config.whoopClientSecret
    private let redirectURI = "fittrack://whoop/callback"
    private let authURL     = "https://api.prod.whoop.com/oauth/oauth2/auth"
    private let tokenURL    = "https://api.prod.whoop.com/oauth/oauth2/token"
    private let cycleURL    = "https://api.prod.whoop.com/developer/v1/cycle"
    private let recoveryURL = "https://api.prod.whoop.com/developer/v1/recovery"
    private let workoutURL  = "https://api.prod.whoop.com/developer/v1/activity/workout"
    private let sleepURL    = "https://api.prod.whoop.com/developer/v1/activity/sleep"
    private let keychainKey = "com.fittrack.whoop.accessToken"

    @Published var isConnected: Bool = false
    @Published var lastCycle: WhoopCycleResult?

    private var authSession: ASWebAuthenticationSession?

    private override init() {
        super.init()
        isConnected = loadToken() != nil
    }

    // MARK: - OAuth2 PKCE

    func connect(presentationContext: ASWebAuthenticationPresentationContextProviding) async throws {
        let codeVerifier  = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let state         = UUID().uuidString

        var components = URLComponents(string: authURL)!
        components.queryItems = [
            .init(name: "response_type",         value: "code"),
            .init(name: "client_id",             value: clientId),
            .init(name: "redirect_uri",          value: redirectURI),
            .init(name: "scope",                 value: "read:recovery read:cycles read:workout read:sleep"),
            .init(name: "state",                 value: state),
            .init(name: "code_challenge",        value: codeChallenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]

        let authorizationURL = components.url!

        let callbackURL: URL = try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: "fittrack"
            ) { url, error in
                if let error { cont.resume(throwing: error); return }
                guard let url else { cont.resume(throwing: WhoopError.noCallbackURL); return }
                cont.resume(returning: url)
            }
            session.presentationContextProvider = presentationContext
            session.prefersEphemeralWebBrowserSession = true
            self.authSession = session
            session.start()
        }
        authSession = nil

        let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)

        if let errorDesc = callbackComponents?.queryItems?.first(where: { $0.name == "error_description" })?.value {
            throw WhoopError.oauthError(errorDesc.replacingOccurrences(of: "+", with: " "))
        }

        let returnedState = callbackComponents?.queryItems?.first(where: { $0.name == "state" })?.value
        if let returnedState, !returnedState.isEmpty {
            guard returnedState.lowercased() == state.lowercased() else { throw WhoopError.invalidState }
        }

        guard let code = callbackComponents?.queryItems?.first(where: { $0.name == "code" })?.value
        else { throw WhoopError.noAuthCode }

        let token = try await exchangeCode(code, codeVerifier: codeVerifier)
        saveToken(token)
        isConnected = true
    }

    func disconnect() {
        deleteToken()
        isConnected = false
        lastCycle = nil
    }

    // MARK: - API

    func fetchTodayCycle() async throws -> WhoopCycleResult {
        guard let token = loadToken() else { throw WhoopError.notAuthenticated }

        func get(_ urlString: String) async throws -> Data {
            var req = URLRequest(url: URL(string: urlString)!)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse {
                if http.statusCode == 401 { throw WhoopError.notAuthenticated }
                if !(200...299).contains(http.statusCode) { throw WhoopError.httpError(http.statusCode) }
            }
            return data
        }

        async let cycleData    = get(cycleURL)
        async let recoveryData = get(recoveryURL)

        let strain   = try? WhoopService.parseLatestStrain(data: try await cycleData)
        let recovery = try? WhoopService.parseLatestRecovery(data: try await recoveryData)

        let result = WhoopCycleResult(recoveryScore: recovery, strainScore: strain)
        lastCycle = result
        return result
    }

    func fetchLatestWorkout() async throws -> WhoopWorkoutResult? {
        guard let token = loadToken() else { throw WhoopError.notAuthenticated }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let fmt = ISO8601DateFormatter()
        var components = URLComponents(string: workoutURL)!
        components.queryItems = [
            .init(name: "start_time", value: fmt.string(from: today)),
            .init(name: "end_time",   value: fmt.string(from: tomorrow)),
            .init(name: "limit",      value: "25"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 { throw WhoopError.notAuthenticated }
            if !(200...299).contains(http.statusCode) { throw WhoopError.httpError(http.statusCode) }
        }
        return try WhoopService.parseLatestWorkout(data: data)
    }

    func fetchTodaySleep() async throws -> Int? {
        guard let token = loadToken() else { throw WhoopError.notAuthenticated }
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let fmt = ISO8601DateFormatter()
        var components = URLComponents(string: sleepURL)!
        components.queryItems = [
            .init(name: "start_time", value: fmt.string(from: yesterday)),
            .init(name: "end_time",   value: fmt.string(from: tomorrow)),
            .init(name: "limit",      value: "5"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 { throw WhoopError.notAuthenticated }
            if !(200...299).contains(http.statusCode) { throw WhoopError.httpError(http.statusCode) }
        }
        return try WhoopService.parseLatestSleep(data: data)
    }

    // MARK: - Parsing (static — unit testable without an instance)

    nonisolated static func parseLatestStrain(data: Data) throws -> Double? {
        struct Score: Decodable { let strain: Double? }
        struct Record: Decodable { let score: Score? }
        struct Response: Decodable { let records: [Record] }
        return try JSONDecoder().decode(Response.self, from: data).records.first?.score?.strain
    }

    nonisolated static func parseLatestRecovery(data: Data) throws -> Int? {
        struct Score: Decodable { let recovery_score: Int? }
        struct Record: Decodable { let score: Score? }
        struct Response: Decodable { let records: [Record] }
        return try JSONDecoder().decode(Response.self, from: data).records.first?.score?.recovery_score
    }

    nonisolated static func parseLatestWorkout(data: Data) throws -> WhoopWorkoutResult? {
        struct Record: Decodable {
            let start: String
            let end: String
            struct Score: Decodable { let strain: Double? }
            let score: Score?
        }
        struct Response: Decodable { let records: [Record] }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return decoded.records
            .compactMap { r -> WhoopWorkoutResult? in
                guard let s = fmt.date(from: r.start), let e = fmt.date(from: r.end) else { return nil }
                return WhoopWorkoutResult(start: s, end: e, strain: r.score?.strain)
            }
            .sorted { $0.start > $1.start }
            .first
    }

    nonisolated static func parseLatestSleep(data: Data) throws -> Int? {
        struct Record: Decodable {
            struct Score: Decodable { let sleep_performance_percentage: Int? }
            let score: Score?
            let end: String
        }
        struct Response: Decodable { let records: [Record] }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return decoded.records
            .compactMap { r -> (date: Date, score: Int)? in
                guard let end = fmt.date(from: r.end), let score = r.score?.sleep_performance_percentage else { return nil }
                return (date: end, score: score)
            }
            .sorted { $0.date > $1.date }
            .first?.score
    }

    // MARK: - PKCE Helpers

    private func base64URLEncoded(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URLEncoded(Data(bytes))
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest) }
        return base64URLEncoded(Data(digest))
    }

    private func exchangeCode(_ code: String, codeVerifier: String) async throws -> String {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var formAllowed = CharacterSet.urlQueryAllowed
        formAllowed.remove(charactersIn: "+=/&")
        let encodedClientId     = clientId.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? clientId
        let encodedClientSecret = clientSecret.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? clientSecret
        let encodedCode         = code.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? code
        let encodedRedirectURI  = redirectURI.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? redirectURI
        let encodedCodeVerifier = codeVerifier.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? codeVerifier
        let body = [
            "grant_type=authorization_code",
            "client_id=\(encodedClientId)",
            "client_secret=\(encodedClientSecret)",
            "code=\(encodedCode)",
            "redirect_uri=\(encodedRedirectURI)",
            "code_verifier=\(encodedCodeVerifier)",
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 { throw WhoopError.notAuthenticated }
            if !(200...299).contains(http.statusCode) { throw WhoopError.httpError(http.statusCode) }
        }
        struct TokenResponse: Decodable { let access_token: String }
        return try JSONDecoder().decode(TokenResponse.self, from: data).access_token
    }

    // MARK: - Keychain

    private func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: keychainKey,
            kSecValueData:   data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: keychainKey,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteToken() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: keychainKey,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum WhoopError: LocalizedError {
    case notAuthenticated
    case noCallbackURL
    case noAuthCode
    case invalidState
    case oauthError(String)
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:       return "Not connected to Whoop. Connect in Settings."
        case .noCallbackURL:          return "Whoop login did not return a callback URL."
        case .noAuthCode:             return "Whoop login did not return an authorization code."
        case .oauthError(let msg):    return "Whoop login failed: \(msg)"
        case .invalidState:        return "Whoop login failed: state parameter mismatch (possible CSRF attack)."
        case .httpError(let code): return "Whoop server returned error \(code)."
        }
    }
}
