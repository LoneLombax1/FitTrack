import Foundation
import AuthenticationServices
import Security
import CommonCrypto

struct WhoopCycleResult {
    let recoveryScore: Int?
    let strainScore: Double?
}

@MainActor
final class WhoopService: NSObject, ObservableObject {

    static let shared = WhoopService()

    // Register at developer.whoop.com — replace with real client ID before use
    private let clientId    = "YOUR_WHOOP_CLIENT_ID"
    private let redirectURI = "fittrack://whoop/callback"
    private let authURL     = "https://api.prod.whoop.com/oauth/oauth2/auth"
    private let tokenURL    = "https://api.prod.whoop.com/oauth/oauth2/token"
    private let cycleURL    = "https://api.prod.whoop.com/developer/v1/cycle"
    private let keychainKey = "com.fittrack.whoop.accessToken"

    @Published var isConnected: Bool = false
    @Published var lastCycle: WhoopCycleResult?

    // Fix #1: Strong reference to prevent ARC from deallocating the session
    private var authSession: ASWebAuthenticationSession?

    // Fix #5: private override init()
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
            .init(name: "scope",                 value: "read:recovery read:cycles read:body_measurement"),
            .init(name: "state",                 value: state),
            .init(name: "code_challenge",        value: codeChallenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]

        let authorizationURL = components.url!

        // Fix #1: Assign to self.authSession so ARC keeps it alive for the duration
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
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session
            session.start()
        }
        // Fix #1: Clear strong reference after continuation resolves
        authSession = nil

        // Fix #4: Validate state parameter against original to prevent CSRF
        let returnedState = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "state" })?.value
        guard returnedState == state else { throw WhoopError.invalidState }

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
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
        var request = URLRequest(url: URL(string: cycleURL)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // Fix #2: Capture and check HTTP status code
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw WhoopError.notAuthenticated
        }
        let result = try WhoopService.parseCycleResponse(data: data)
        lastCycle = result
        return result
    }

    // MARK: - Parsing (static — unit testable without an instance)

    nonisolated static func parseCycleResponse(data: Data) throws -> WhoopCycleResult {
        struct Response: Decodable {
            struct Score: Decodable {
                let recovery_score: Int?
                let strain: Double?
            }
            let score: Score?
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return WhoopCycleResult(
            recoveryScore: decoded.score?.recovery_score,
            strainScore: decoded.score?.strain
        )
    }

    // MARK: - PKCE Helpers

    // Fix #6: Shared base64url encoding helper
    private func base64URLEncoded(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        // Fix #6: Use shared helper
        return base64URLEncoded(Data(bytes))
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest) }
        // Fix #6: Use shared helper
        return base64URLEncoded(Data(digest))
    }

    private func exchangeCode(_ code: String, codeVerifier: String) async throws -> String {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // Fix #3: Percent-encode form body values per RFC 6749
        let encodedClientId     = clientId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clientId
        let encodedCode         = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? code
        let encodedRedirectURI  = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
        let encodedCodeVerifier = codeVerifier.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? codeVerifier
        let body = [
            "grant_type=authorization_code",
            "client_id=\(encodedClientId)",
            "code=\(encodedCode)",
            "redirect_uri=\(encodedRedirectURI)",
            "code_verifier=\(encodedCodeVerifier)",
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        // Fix #2: Capture and check HTTP status code
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw WhoopError.notAuthenticated
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
    // Fix #4: Added invalidState case for CSRF protection
    case invalidState

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not connected to Whoop. Connect in Settings."
        case .noCallbackURL:    return "Whoop login did not return a callback URL."
        case .noAuthCode:       return "Whoop login did not return an authorization code."
        case .invalidState:     return "Whoop login failed: state parameter mismatch (possible CSRF attack)."
        }
    }
}
