//
//  ProfileView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/14.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var isImagePickerPresented = false
    @State private var isEditingName = false
    @State private var isEditingPosition = false
    @State private var isEditingEmail = false
    @State private var isEditingPassword = false
    @State private var isSettingsPresented = false
    
    @State private var tempName = ""
    @State private var tempPosition = ""
    @State private var tempEmail = ""
    @State private var tempPassword = ""
    
    @State private var isLoading = true
    @State private var selectedImageData: Data? = nil

    var body: some View {
        ZStack {
            List {
                Section {
                    VStack(spacing: 0) {
                        ZStack {
                            if let urlString = auth.user?.imageURL, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image.resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                            }
                            Button(action: { isImagePickerPresented.toggle() }) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.secondary)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .offset(x: 35, y: 35)
                        }
                        .frame(width: 100, height: 100)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                
                Section("Account Info") {
                    Button(action: {
                        tempName = auth.user?.name ?? ""
                        isEditingName = true
                    }) {
                        HStack {
                            Text("Full Name")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(auth.user?.name ?? "No name")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        tempPosition = auth.user?.position ?? ""
                        isEditingPosition = true
                    }) {
                        HStack {
                            Text("Team or Position")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(auth.user?.position ?? "No Team")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        tempEmail = auth.user?.email ?? ""
                        isEditingEmail = true
                    }) {
                        HStack {
                            Text("Email Address")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(auth.user?.email ?? "No email")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("Security") {
                    Button(action: {
                        tempPassword = ""
                        isEditingPassword = true
                    }) {
                        HStack {
                            Text("Account Password")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("••••••••")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("Preferences") {
                    Button(action: { isSettingsPresented = true }) {
                        HStack {
                            Text("Account Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .disabled(isLoading)
            
            if isLoading {
                LoadingOverlayView()
            }
        }
        .onAppear {
            if auth.token != nil {
                Task {
                    isLoading = true
                    await auth.fetchProfile(token: auth.token!)
                    
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    isLoading = false
                }
            } else {
                isLoading = false
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(isPresented: $isImagePickerPresented, imageData: $selectedImageData)
        }
        .onChange(of: selectedImageData) { newData in
            if let data = newData {
                Task {
                    do {
                        guard let currentToken = auth.token else {
                            return
                        }
                        let _ = try await APIClient.shared.uploadProfileImage(imageData: data, token: currentToken)
                        await auth.fetchProfile(token: currentToken)
                    } catch {
                        print("Image upload failed: \(error)")
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingName) {
            EditableSectionView(
                title: "Change Name",
                description: "Enter your full name as it should appear on your profile.",
                currentValue: $tempName,
                isPresented: $isEditingName,
                isPassword: false,
                onDone: { self.updateProfileField(field: "Name", newValue: $0) }
            )
        }
        .sheet(isPresented: $isEditingPosition) {
            EditableSectionView(
                title: "Change Position",
                description: "Update your current job title or position in the company.",
                currentValue: $tempPosition,
                isPresented: $isEditingPosition,
                isPassword: false,
                onDone: { self.updateProfileField(field: "Position", newValue: $0) }
            )
        }
        .sheet(isPresented: $isEditingEmail) {
            EditableSectionView(
                title: "Change Email",
                description: "Enter a new email address. You will use this to login.",
                currentValue: $tempEmail,
                isPresented: $isEditingEmail,
                isPassword: false,
                onDone: { newValue in
                    if !newValue.isEmpty { self.updateProfileField(field: "Email", newValue: newValue) }
                }
            )
        }
        .sheet(isPresented: $isEditingPassword) {
            EditableSectionView(
                title: "Change Password",
                description: "Enter a new secure password. You will be logged out then.",
                currentValue: $tempPassword,
                isPresented: $isEditingPassword,
                isPassword: true,
                onDone: { self.updateProfileField(field: "Password", newValue: $0) }
            )
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationView {
                SettingsView()
            }
        }
    }
    
    func updateProfileField(field: String, newValue: String) {
        Task {
            do {
                try await APIClient.shared.updateProfile(
                    name: field == "Name" ? newValue : nil,
                    position: field == "Position" ? newValue : nil,
                    email: field == "Email" ? newValue : nil,
                    password: field == "Password" ? newValue : nil,
                    token: auth.token!
                )
                if field == "Password" {
                    auth.logout()
                } else {
                    await auth.fetchProfile(token: auth.token!)
                }
            } catch {
                print("Profile update failed: \(error)")
            }
        }
    }
}


struct LoadingOverlayView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0.0 : 1.0)

                    Circle()
                        .fill(Color.primary.opacity(0.4))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.0 : 1.0)

                    Circle()
                        .fill(Color.primary)
                        .frame(width: 60, height: 60)
                }
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )

                Text("Loading Profile...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var imageData: Data?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.isPresented = false
                if let data = selectedImage.jpegData(compressionQuality: 0.5) {
                    parent.imageData = data
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}


struct EditableSectionView: View {
    let title: String
    let description: String
    @Binding var currentValue: String
    @Binding var isPresented: Bool
    let isPassword: Bool
    let onDone: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                if isPassword {
                    SecureField("Enter new password", text: $currentValue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .font(.body)
                } else {
                    TextField("Enter new value", text: $currentValue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .font(.body)
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 24)
            
            Button("Save Changes") {
                isPresented = false
                onDone(currentValue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding(.top, 30)
        .padding(.bottom, 20)
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
    }
}


struct SectionHeader<Content: View>: View {
    let title: String
    let content: Content
    let onEdit: (() -> Void)?
    let isSettingsStyle: Bool
    
    init(title: String, isSettingsStyle: Bool = false, @ViewBuilder content: () -> Content, onEdit: (() -> Void)? = nil) {
        self.title = title
        self.content = content()
        self.onEdit = onEdit
        self.isSettingsStyle = isSettingsStyle
    }

    var body: some View {
        Button(action: {
            onEdit?()
        }) {
            HStack {
                if isSettingsStyle {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.primary)
                    Text(title)
                        .foregroundColor(.primary)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        content
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(isSettingsStyle ? Color.primary.opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
