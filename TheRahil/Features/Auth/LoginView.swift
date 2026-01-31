import SwiftUI

struct LoginView: View {
    @StateObject var vm = AuthViewModel()
    @EnvironmentObject var auth: AuthManager
    
    @State private var isLoading = false

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

                Spacer()
            }
            .padding()
            .foregroundColor(.primary)
            if isLoading {
                AuthLoadingView()
            }
        }
    }
}
