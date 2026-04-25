//
//  ReactionPickerView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/17.
//

import SwiftUI
import Combine
import _PhotosUI_SwiftUI


struct ReactionPickerView: View {
    let emojis: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("React")
                .font(.headline)
                .padding(.top)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: { onSelect(emoji) }) {
                        Text(emoji)
                            .font(.system(size: 32))
                    }
                }
            }
            .padding()

            Spacer()
        }
    }
}

struct AttachmentPickerSheet: View {
    let onImageSelected: (Data, String) -> Void
    let onVideoSelected: (Data, String) -> Void

    @State private var selectedImageItem: PhotosPickerItem? = nil
    @State private var selectedVideoItem: PhotosPickerItem? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                PhotosPicker(selection: $selectedImageItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("Photo")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }

                PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                    VStack(spacing: 12) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        Text("Video")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
            .padding()
            .navigationTitle("Send Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedImageItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        let fileName = "IMG_\(Date().timeIntervalSince1970).jpg"
                        onImageSelected(data, fileName)
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedVideoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        let fileName = "VID_\(Date().timeIntervalSince1970).mp4"
                        onVideoSelected(data, fileName)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let onDocumentSelected: (Data, String, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [.pdf, .spreadsheet, .presentation, .data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentSelected: onDocumentSelected)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentSelected: (Data, String, String) -> Void

        init(onDocumentSelected: @escaping (Data, String, String) -> Void) {
            self.onDocumentSelected = onDocumentSelected
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                let mimeType = getMimeType(for: url)

                onDocumentSelected(data, fileName, mimeType)
            } catch {
                print("Error reading document: \(error)")
            }
        }

        private func getMimeType(for url: URL) -> String {
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "pdf":
                return "application/pdf"
            case "xlsx", "xls":
                return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            case "csv":
                return "text/csv"
            case "doc", "docx":
                return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            default:
                return "application/octet-stream"
            }
        }
    }
}
