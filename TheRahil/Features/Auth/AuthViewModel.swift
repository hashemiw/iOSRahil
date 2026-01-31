import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var position = ""
    @Published var errorMessage: String?

    func login(auth: AuthManager) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password required"
            return
        }

        let isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")
        if isBiometricEnabled && BiometricManager.shared.canAuthenticate() {
            do {
                try await BiometricManager.shared.authenticate(reason: "برای ورود به حساب کاربری خود، اثر انگشت خود را اسکن کنید.")
            } catch {
                errorMessage = "احراز هویت بیومتریک لغو شد"
                return
            }
        }

        do {
            let loginData = try await APIClient.shared.request(
                path: "/auth/login",
                method: "POST",
                body: [
                    "email": email.lowercased(),
                    "password": password
                ]
            )
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let authResponse = try decoder.decode(AuthResponse.self, from: loginData)
            
            auth.token = authResponse.accessToken
            auth.refreshToken = authResponse.refreshToken
            let deviceData = try await APIClient.shared.request(
                path: "/api/devices/register",
                method: "POST",
                token: authResponse.accessToken,
                body: [
                    "UUID": DeviceManager.shared.uuid,
                    "Platform": "iOS"
                ]
            )
            
            let deviceResponse = try JSONDecoder().decode(DeviceRegisterResponse.self, from: deviceData)
            DeviceManager.shared.deviceID = deviceResponse.deviceID
            await auth.fetchProfile(token: authResponse.accessToken)
                        
        } catch {
            errorMessage = "Invalid credentials or server error"
        }
    }
    
    func signup(auth: AuthManager) async {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty, !position.isEmpty else {
            errorMessage = "همه فیلدها الزامی هستند"
            return
        }

        do {

            try await APIClient.shared.request(
                path: "/auth/signup",
                method: "POST",
                body: [
                    "email": email.lowercased(),
                    "password": password,
                    "name": name,
                    "position": position
                ]
            )
            
            let loginData = try await APIClient.shared.request(
                path: "/auth/login",
                method: "POST",
                body: [
                    "email": email.lowercased(),
                    "password": password
                ]
            )
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let authResponse = try decoder.decode(AuthResponse.self, from: loginData)
            
            auth.token = authResponse.accessToken
            auth.refreshToken = authResponse.refreshToken
            let deviceData = try await APIClient.shared.request(
                path: "/api/devices/register",
                method: "POST",
                token: authResponse.accessToken,
                body: [
                    "UUID": DeviceManager.shared.uuid,
                    "Platform": "iOS"
                ]
            )
            
            let deviceResponse = try JSONDecoder().decode(DeviceRegisterResponse.self, from: deviceData)
            DeviceManager.shared.deviceID = deviceResponse.deviceID
            
            await auth.fetchProfile(token: authResponse.accessToken)
            
            if BiometricManager.shared.canAuthenticate() {
                do {
                    try await BiometricManager.shared.authenticate(reason: "برای فعال‌سازی ورود سریع، اثر انگعت خود را تایید کنید.")
                    UserDefaults.standard.set(true, forKey: "biometric_enabled")
                } catch {
                }
            }
            
            
        } catch {
            errorMessage = "ثبت نام ناموفق بود"
        }
    }
}
