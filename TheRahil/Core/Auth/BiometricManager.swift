//
//  BiometricManager.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/16.
//

import LocalAuthentication

class BiometricManager {
    static let shared = BiometricManager()
    private init() {}

    enum BiometricError: Error {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancel
    }

    func canAuthenticate() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedCancelTitle = "لغو"
        
        let result = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
        
        if !result {
            throw BiometricError.authenticationFailed
        }
    }
}
