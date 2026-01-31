import SwiftUI

struct SignupView: View {
    @StateObject var vm = AuthViewModel()
    @EnvironmentObject var auth: AuthManager
    
    @State private var isLoading = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle.bold())

                    Text("Start tracking attendance")
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    AppTextField(title: "Email", text: $vm.email)
                    AppTextField(title: "Password", text: $vm.password, isSecure: true)
                    AppTextField(title: "Name", text: $vm.name)
                    AppTextField(title: "Position", text: $vm.position)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(title: "Signup") {
                    Task {
                        isLoading = true
                        await vm.signup(auth: auth)
                        isLoading = false
                    }
                }
                .disabled(isLoading)
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
