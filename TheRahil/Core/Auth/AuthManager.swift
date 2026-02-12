import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var token: String? {
        didSet {
            UserDefaults.standard.set(token, forKey: "token")
        }
    }
    
    @Published var user: User? {
        didSet {
            if let user = user {
                if let encoded = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(encoded, forKey: "user")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "user")
            }
        }
    }
    
    var refreshToken: String? {
        get {
            let token = UserDefaults.standard.string(forKey: "refresh_token")
            return token
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "refresh_token")
        }
    }
    
    init() {
        token = UserDefaults.standard.string(forKey: "token")
        refreshToken = UserDefaults.standard.string(forKey: "refresh_token")
        
        if let data = UserDefaults.standard.data(forKey: "user"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: data) {
            self.user = decodedUser
        }
    }
    
    func fetchProfile(token: String) async {
        do {
            let data = try await APIClient.shared.request(
                path: "/api/profile",
                method: "GET",
                token: token
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            // decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            struct ProfileResponse: Codable {
                let user: User
            }
            
            do {
                let response = try decoder.decode(ProfileResponse.self, from: data)
                self.user = response.user
                print("imageURL \(response.user.imageURL ?? "nil")")
            } catch {
                print("decode err: \(error)")
            }
        
            
        } catch {
            print("err: \(error)")

            if let urlError = error as? URLError, urlError.code == .userAuthenticationRequired {
                do {
                    try await refreshTokens()
                    if let newToken = self.token {
                        await fetchProfile(token: newToken)
                    }
                } catch {
                    logout()
                }
            }
        }
    }
    func refreshTokens() async throws {
        guard let currentRefreshToken = self.refreshToken, !currentRefreshToken.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let body = ["refresh_token": currentRefreshToken]
        
        do {
            let data = try await APIClient.shared.request(
                path: "/auth/refresh",
                method: "POST",
                body: body
            )
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(AuthResponse.self, from: data)
            
            self.token = response.accessToken
            self.refreshToken = response.refreshToken
            
            
        } catch {
            if (error as? URLError)?.code == .userAuthenticationRequired {
                logout()
            }
            throw error
        }
    }
    
    func logout() {
        token = nil
        user = nil
        refreshToken = nil
        
        UserDefaults.standard.removeObject(forKey: "token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "user")
        UserDefaults.standard.removeObject(forKey: "device_id")
        
    }
}


class AuthDebug {
    static func printAuthStatus() {
        
        let token = UserDefaults.standard.string(forKey: "token")
        let refreshToken = UserDefaults.standard.string(forKey: "refresh_token")
        
        
        if let data = UserDefaults.standard.data(forKey: "user"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
        } else {
        }
        
        let deviceID = UserDefaults.standard.value(forKey: "device_id") as? UInt
    }
    
    static func clearAll() {
        
        UserDefaults.standard.removeObject(forKey: "token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "user")
        UserDefaults.standard.removeObject(forKey: "device_id")
        UserDefaults.standard.removeObject(forKey: "biometric_enabled")
        
    }
}
