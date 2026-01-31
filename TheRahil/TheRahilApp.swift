//
//  TheRahilApp.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/1.
//

import SwiftUI

@main
struct TheRahilApp: App {
    @StateObject var auth = AuthManager()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    
    var body: some Scene {
        WindowGroup {
            if auth.token == nil {
                NavigationStack {
                    LoginView()
                }
                .environmentObject(auth)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environment(\.locale, Locale(identifier: selectedLanguage))
            } else {
                MainTabView()
                    .environmentObject(auth)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                    .environment(\.locale, Locale(identifier: selectedLanguage))
            }
        }
    }
}



extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
}
