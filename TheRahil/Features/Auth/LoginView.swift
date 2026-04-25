import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject var vm = AuthViewModel()
    @State private var isLoading = false
    @State private var showLocalPasscodePrompt = false
    @State private var localPasscodeInput = ""
    @State private var passcodeError = ""
    
    @AppStorage("is_biometric_enabled") private var isBiometricEnabled = false
    @AppStorage("local_passcode") private var storedLocalPasscode: String = ""
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.largeTitle.bold())

                    Text("Sign in to continue")
                        .foregroundColor(.secondary)
                }

                if auth.token == nil || (!isBiometricEnabled && storedLocalPasscode.isEmpty) {
                    VStack(spacing: 16) {
                        AppTextField(title: "Email", text: $vm.email)
                        AppTextField(title: "Password", text: $vm.password, isSecure: true)
                    }

                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryButton(title: "Login") {
                        Task {
                            isLoading = true
                            await vm.login(auth: auth)
                            isLoading = false
                        }
                    }
                    .disabled(isLoading)
                    
                    NavigationLink("Create an account", destination: SignupView())
                        .font(.footnote)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: BiometricManager.shared.getBiometricType() == .faceID ? "faceid" : "touchid")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Tap to unlock")
                            .font(.headline)
                        
                        Button(action: triggerBiometricOrPasscode) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "lock.open.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .foregroundColor(.primary)
            
            if isLoading {
                AuthLoadingView()
            }
        }
        .onAppear {
            attemptAutoLogin()
        }
        .sheet(isPresented: $showLocalPasscodePrompt) {
            LocalPasscodePromptView(
                isPresented: $showLocalPasscodePrompt,
                passcode: storedLocalPasscode,
                onSuccess: {
                    isLoading = false
                }
            )
        }
    }
    
    func attemptAutoLogin() {
        guard auth.token != nil else { return }
        
        if isBiometricEnabled && BiometricManager.shared.canAuthenticate() {
            triggerBiometric()
        } else if !storedLocalPasscode.isEmpty {
            showLocalPasscodePrompt = true
        }
    }
    
    func triggerBiometricOrPasscode() {
        if isBiometricEnabled {
            triggerBiometric()
        } else if !storedLocalPasscode.isEmpty {
            showLocalPasscodePrompt = true
        }
    }
    
    func triggerBiometric() {
        Task {
            isLoading = true
            do {
                try await BiometricManager.shared.authenticate(reason: "برای ورود به حساب کاربری خود، احراز هویت کنید.")
                isLoading = false
            } catch {
                isLoading = false
                if case .userFallback = error as? BiometricManager.BiometricError {
                    showLocalPasscodePrompt = true
                }
            }
        }
    }
}

struct LocalPasscodePromptView: View {
    @Binding var isPresented: Bool
    let passcode: String
    let onSuccess: () -> Void
    
    @State private var input = ""
    @State private var error = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Enter Passcode")
                    .font(.title2)
                
                SecureField("Passcode", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding()
                
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                Button("Unlock") {
                    if input == passcode {
                        onSuccess()
                        isPresented = false
                    } else {
                        error = "Incorrect"
                        input = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Security Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        // AuthManager.shared.logout()
                    }
                }
            }
        }
    }
}
