//
//  SettingsView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/17.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    
    let languages = [
        ("en", "English"),
        ("ar", "العربية"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("zh", "中文")
    ]
    
    var body: some View {
        List {
            Section(header: Text("Preferences")) {
                HStack {
                    Image(systemName: isDarkMode ? "moon.fill" : "moon")
                        .foregroundColor(.blue)
                    Text("Dark Mode")
                    Spacer()
                    Toggle("", isOn: $isDarkMode)
                        .labelsHidden()
                }
                
                NavigationLink(destination: LanguageSelectionView(selectedLanguage: $selectedLanguage)) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("Language")
                        Spacer()
                        if let langName = languages.first(where: { $0.0 == selectedLanguage })?.1 {
                            Text(langName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // داخل SettingsView
            Section(header: Text("Security")) {
                NavigationLink(destination: SecuritySettingsView()) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.blue)
                        Text("App Lock")
                        Spacer()
                        // نمایش وضعیت روشن یا خاموش
                        if ((UserDefaults.standard.string(forKey: "local_app_passcode")?.isEmpty) == nil) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                // سایر آیتم‌ها...
            }
            
            Section {
                Button(role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("Close Settings")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            if selectedLanguage != "en" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let alert = UIAlertController(
                        title: "Restart Required",
                        message: "To apply the new language, please restart the app.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    
                    if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                        rootVC.present(alert, animated: true)
                    }
                }
            }
        }
    }
}

import SwiftUI

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: String
    @Environment(\.presentationMode) var presentationMode
    
    let languages = [
        ("en", "English"),
        ("ar", "العربية"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("zh", "中文")
    ]
    
    var body: some View {
        List {
            ForEach(languages, id: \.0) { code, name in
                Button(action: {
                    selectedLanguage = code
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(name)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedLanguage == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}




import Foundation
import SwiftUI

class AppSecurityDebug {
    
    static let passcodeKey = "local_app_passcode"
    
    static func logSecurityStatus() {
        let storedCode = UserDefaults.standard.string(forKey: passcodeKey)
        
        print("========================================")
        print("🔒 APP SECURITY DEBUG LOG")
        print("========================================")
        
        if let code = storedCode {
            print("✅ Status: LOCKED (Passcode is SET)")
            print("🔑 Stored Passcode: \(code)")
            print("🔑 Passcode Length: \(code.count) digits")
        } else {
            print("⚠️ Status: UNLOCKED (No Passcode found)")
            print("🔑 Stored Passcode: nil")
        }
        
        print("========================================")
    }
    
    static func resetPasscode() {
        UserDefaults.standard.removeObject(forKey: passcodeKey)
        print("🧹 Passcode has been RESET. App is now UNLOCKED.")
    }
}
