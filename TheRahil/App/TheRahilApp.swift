//
//  TheRahilApp.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/1.
//

import SwiftUI
import Combine

@main
struct TheRahilApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.auth)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environment(\.locale, Locale(identifier: selectedLanguage))
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var appPhase: AppPhase = .splash
    @Published var isAppLocked = true
    let auth = AuthManager.shared
    
    enum AppPhase {
        case splash
        case auth
        case locked
        case main
    }
    
    init() {
        Task {
            await determineInitialPhase()
        }
    }
    
    func determineInitialPhase() async {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        if auth.token == nil {
            appPhase = .auth
        } else if !localPasscode.isEmpty {
            appPhase = .locked
        } else {
            appPhase = .main
        }
    }
    
    private var localPasscode: String {
        UserDefaults.standard.string(forKey: "local_app_passcode") ?? ""
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var auth: AuthManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @AppStorage("local_app_passcode") private var localPasscode = ""
    
    var body: some View {
        ZStack {
            switch appState.appPhase {
            case .splash:
                SplashView()
                
            case .auth:
                NavigationStack {
                    LoginView()
                }
                .environmentObject(auth)
                
            case .locked:
                AppLockView(isUnlocked: $appState.isAppLocked, passcode: localPasscode)
                    .onChange(of: appState.isAppLocked) { isUnlocked in
                        if !isUnlocked {
                            withAnimation {
                                appState.appPhase = .main
                            }
                        }
                    }
                
            case .main:
                MainTabView()
                    .environmentObject(auth)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.locale, Locale(identifier: selectedLanguage))
    }
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("TheRahil")
                    .font(.largeTitle.bold())
                    .opacity(opacity)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
