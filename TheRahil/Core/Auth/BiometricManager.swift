//
//  BiometricManager.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/16.
//

import LocalAuthentication
import Foundation

class BiometricManager {
    static let shared = BiometricManager()
    private init() {}

    enum BiometricType {
        case none
        case touchID
        case faceID
    }
    
    enum BiometricError: Error, LocalizedError {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancel
        case userFallback
        case systemCancel
        
        var errorDescription: String? {
            switch self {
            case .notAvailable: return "Biometric authentication is not available on this device."
            case .notEnrolled: return "No biometric identity enrolled."
            case .authenticationFailed: return "Authentication failed."
            case .userCancel: return "User cancelled authentication."
            case .userFallback: return "User chose to use password."
            case .systemCancel: return "System cancelled authentication."
            }
        }
    }

    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            default:
                return .none
            }
        }
        
        return .none
    }
    
    func canAuthenticate() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedCancelTitle = "لغو"
        context.localizedFallbackTitle = "استفاده از رمز عبور"
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if !result {
                throw BiometricError.authenticationFailed
            }
        } catch let error {
            if let laError = error as? LAError {
                switch laError.code {
                case .userFallback, .appCancel:
                    throw BiometricError.userFallback
                case .userCancel:
                    throw BiometricError.userCancel
                case .systemCancel:
                    throw BiometricError.systemCancel
                default:
                    throw BiometricError.authenticationFailed
                }
            }
            throw BiometricError.authenticationFailed
        }
    }
}
