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
    
    @State private var isLoading = false
    @State private var selectedImageData: Data? = nil
    
    // --- حذف currentImageURL و uiImage ---
    // مستقیماً از auth.user?.imageURL استفاده میکنیم

    var body: some View {
        ZStack {
            List {
                Section {
                    VStack(spacing: 0) {
                        // نمایش عکس مستقیم از URL داخل auth.user
                        ZStack {
                            ProfileImageView(imageURL: auth.user?.imageURL)
                                .frame(width: 100, height: 100)
                            
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
            .refreshable {
                await refreshProfile()
            }
            
            if isLoading {
                LoadingOverlayView()
            }
        }
        .onAppear {
            Task {
                await refreshProfile()
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(isPresented: $isImagePickerPresented, imageData: $selectedImageData)
        }
        .onChange(of: selectedImageData) { newData in
            if let data = newData {
                Task {
                    await uploadProfileImage(data)
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
    
    private func refreshProfile() async {
        guard let token = auth.token else { return }
        await auth.fetchProfile(token: token)
    }
    
    private func uploadProfileImage(_ data: Data) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let token = auth.token else { return }
            
            print("🚀 Starting upload...")
            let returnedURL = try await APIClient.shared.uploadProfileImage(imageData: data, token: token)
            print("✅ Upload Success. Server returned URL: \(returnedURL)")
            
            // آپدیت مستقیم user object
            if var currentUser = auth.user {
                currentUser.imageURL = returnedURL
                auth.user = currentUser
            }
            
            // دریافت مجدد پروفایل برای اطمینان
            await refreshProfile()
            
        } catch {
            print("❌ Error uploading image: \(error)")
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
                    await refreshProfile()
                }
            } catch {
                print("Profile update failed: \(error)")
            }
        }
    }
}

// MARK: - کامپوننت مجزا برای نمایش عکس پروفایل
struct ProfileImageView: View {
    let imageURL: String?
    @State private var uiImage: UIImage? = nil
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if isLoading {
                ProgressView()
                    .frame(width: 100, height: 100)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: imageURL) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let urlString = imageURL, !urlString.isEmpty,
              let url = URL(string: urlString) else {
            uiImage = nil
            return
        }
        
        // چک کردن کش
        if let cachedImage = ImageCache.shared.get(forKey: urlString) {
            print("✅ Loaded from cache: \(urlString)")
            self.uiImage = cachedImage
            return
        }
        
        // دانلود
        isLoading = true
        print("📥 Downloading image: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Download error: \(error)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    print("✅ Downloaded successfully")
                    ImageCache.shared.set(image, forKey: urlString)
                    self.uiImage = image
                } else {
                    print("❌ Failed to convert data to image")
                }
            }
        }.resume()
    }
}

// MARK: - کش قوی‌تر با UserDefaults پشتیبان
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // کش رو به 50 مگابایت محدود کن
        cache.totalCostLimit = 50 * 1024 * 1024
        
        // دایرکتوری کش
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ProfileImages", isDirectory: true)
        
        // ایجاد دایرکتوری اگر وجود نداره
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func get(forKey key: String) -> UIImage? {
        // اول از NSCache
        if let image = cache.object(forKey: key as NSString) {
            return image
        }
        
        // بعد از دیسک
        let fileName = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            cache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    func set(_ image: UIImage, forKey key: String) {
        // ذخیره در NSCache
        cache.setObject(image, forKey: key as NSString)
        
        // ذخیره روی دیسک
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let fileName = key.replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_")
            let fileURL = self.cacheDirectory.appendingPathComponent(fileName)
            
            if let data = image.jpegData(compressionQuality: 0.7) {
                try? data.write(to: fileURL)
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
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
