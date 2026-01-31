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
            
            Section(header: Text("Security")) {
                HStack {
                    Image(systemName: "faceid")
                    Text("Biometric Login")
                    Spacer()
                    Text("Enabled")
                        .foregroundColor(.green)
                }
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
