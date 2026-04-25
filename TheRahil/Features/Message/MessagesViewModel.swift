//
//  MessagesViewModel.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/17.
//


import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers
import Combine


@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessageText = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var currentTeam: String? = nil
    @Published var errorMessage: String?

    @Published var replyingTo: Message? = nil
    @Published var editingMessage: Message? = nil
    @Published var selectedPhotoItem: PhotosPickerItem? = nil
    @Published var selectedVideoItem: PhotosPickerItem? = nil
    @Published var isUploading = false    
    @Published var uploadProgress: Double = 0

    func loadMessages(token: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            messages = try await APIClient.shared.getMessages(token: token)
            currentTeam = AuthManager.shared.user?.team
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMessagesForTeam(token: String, team: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            messages = try await APIClient.shared.getMessagesByTeam(token: token, team: team)
            currentTeam = team
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage(token: String) async {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        defer { isSending = false }
        do {
            let newMessage = try await APIClient.shared.sendMessage(
                token: token,
                content: newMessageText,
                replyToID: replyingTo?.id
            )
            messages.append(newMessage)
            newMessageText = ""
            replyingTo = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendFileMessage(token: String, fileData: Data, fileName: String, mimeType: String, caption: String = "") async {
        isUploading = true
        defer { isUploading = false }
        do {
            let newMessage = try await APIClient.shared.sendFileMessage(
                token: token,
                fileData: fileData,
                fileName: fileName,
                mimeType: mimeType,
                content: caption,
                replyToID: replyingTo?.id
            )
            messages.append(newMessage)
            replyingTo = nil
            selectedPhotoItem = nil
            selectedVideoItem = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func editMessage(token: String, message: Message, newContent: String) async {
        guard !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        defer { isSending = false }
        do {
            let updatedMessage = try await APIClient.shared.updateMessage(token: token, messageID: message.id, content: newContent)
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = updatedMessage
            }
            editingMessage = nil
            newMessageText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMessage(token: String, message: Message) async {
        do {
            try await APIClient.shared.deleteMessage(token: token, messageID: message.id)
            messages.removeAll { $0.id == message.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleReaction(token: String, message: Message, emoji: String) async {
        let hasReacted = message.reactions?.contains { $0.emoji == emoji && $0.userID == AuthManager.shared.user?.id } ?? false

        do {
            if hasReacted {
                try await APIClient.shared.removeReaction(token: token, messageID: message.id, emoji: emoji)
            } else {
                _ = try await APIClient.shared.addReaction(token: token, messageID: message.id, emoji: emoji)
            }
            await loadMessages(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startReply(to message: Message) {
        replyingTo = message
        newMessageText = ""
    }

    func startEdit(message: Message) {
        editingMessage = message
        newMessageText = message.content
    }

    func cancelReplyOrEdit() {
        replyingTo = nil
        editingMessage = nil
        newMessageText = ""
    }
}
