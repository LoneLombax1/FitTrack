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

    override init() {
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
            session.start()
        }

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
        let (data, _) = try await URLSession.shared.data(for: request)
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

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest) }
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func exchangeCode(_ code: String, codeVerifier: String) async throws -> String {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type=authorization_code",
            "client_id=\(clientId)",
            "code=\(code)",
            "redirect_uri=\(redirectURI)",
            "code_verifier=\(codeVerifier)",
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: request)
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

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not connected to Whoop. Connect in Settings."
        case .noCallbackURL:    return "Whoop login did not return a callback URL."
        case .noAuthCode:       return "Whoop login did not return an authorization code."
        }
    }
}
