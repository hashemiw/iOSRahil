//
//  TeamMessagesView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/6.
//

import SwiftUI
import Combine


struct TeamMessagesView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var viewModel = MessagesViewModel()
    @StateObject private var audioPlayer = AudioPlayerManager()
    @State private var selectedTeam: String? = nil
    @State private var showTeamPicker = false
    @State private var showAttachmentSheet = false
    @State private var showDocumentPicker = false
    @State private var isRecording = false
    @State private var audioRecorder = AudioRecorderManager()

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                messagesList

                if let replyTo = viewModel.replyingTo {
                    ReplyPreviewView(message: replyTo) {
                        viewModel.cancelReplyOrEdit()
                    }
                }

                if let editing = viewModel.editingMessage {
                    EditingPreviewView(message: editing) {
                        viewModel.cancelReplyOrEdit()
                    }
                }

                if viewModel.currentTeam != nil && !viewModel.currentTeam!.isEmpty {
                    MessageInputView(
                        viewModel: viewModel,
                        audioRecorder: audioRecorder,
                        audioPlayer: audioPlayer,
                        onAttachmentTap: { showAttachmentSheet = true },
                        onRecordTap: {
                            if isRecording {
                                audioRecorder.stopRecording()
                                if let url = audioRecorder.recordingURL {
                                    if let data = try? Data(contentsOf: url) {
                                        print("📊 File size: \(data.count) bytes")
                                        
                                        Task {
                                            await viewModel.sendFileMessage(
                                                token: auth.token!,
                                                fileData: data,
                                                fileName: "voice_\(Date().timeIntervalSince1970).m4a",
                                                mimeType: "audio/mp4"
                                            )
                                        }
                                    }
                                }
                            } else {
                                audioRecorder.startRecording()
                            }
                            isRecording.toggle()
                        },
                        isRecording: isRecording,
                        auth: auth
                    )
                } else {
                    noTeamView
                }
            }
        }
        .navigationTitle("Team Messages")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMessages(token: auth.token!)
        }
        .sheet(isPresented: $showTeamPicker) {
            TeamPickerSheet(
                selectedTeam: $selectedTeam,
                isPresented: $showTeamPicker,
                onSelect: { team in
                    Task {
                        await viewModel.loadMessagesForTeam(token: auth.token!, team: team)
                    }
                }
            )
        }
        .sheet(isPresented: $showAttachmentSheet) {
            AttachmentPickerSheet(
                onImageSelected: { data, name in
                    Task {
                        await viewModel.sendFileMessage(
                            token: auth.token!,
                            fileData: data,
                            fileName: name,
                            mimeType: "image/jpeg"
                        )
                    }
                },
                onVideoSelected: { data, name in
                    Task {
                        await viewModel.sendFileMessage(
                            token: auth.token!,
                            fileData: data,
                            fileName: name,
                            mimeType: "video/mp4"
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { data, name, mimeType in
                Task {
                    await viewModel.sendFileMessage(
                        token: auth.token!,
                        fileData: data,
                        fileName: name,
                        mimeType: mimeType
                    )
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "person.3.fill")
                .foregroundColor(.blue)
            Text(viewModel.currentTeam ?? "No Team")
                .font(.headline)
            Spacer()
            if auth.user?.role == "admin" {
                Button("Change") {
                    showTeamPicker = true
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var messagesList: some View {
        Group {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading messages...")
                Spacer()
            } else if viewModel.messages.isEmpty {
                Spacer()
                emptyStateView
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isCurrentUser: message.userID == auth.user?.id,
                                    audioPlayer: audioPlayer,
                                    onReply: { viewModel.startReply(to: message) },
                                    onEdit: { viewModel.startEdit(message: message) },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteMessage(token: auth.token!, message: message)
                                        }
                                    },
                                    onReaction: { emoji in
                                        Task {
                                            await viewModel.toggleReaction(token: auth.token!, message: message, emoji: emoji)
                                        }
                                    },
                                    auth: auth,
                                    viewModel: viewModel
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No messages yet")
                .foregroundColor(.secondary)
            Text("Be the first to send a message!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var noTeamView: some View {
        Text("You are not assigned to any team")
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
    }
}


struct TeamPickerSheet: View {
    @Binding var selectedTeam: String?
    @Binding var isPresented: Bool
    let onSelect: (String) -> Void
    
    @State private var teams: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView()
                } else if teams.isEmpty {
                    Text("No teams found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(teams, id: \.self) { team in
                        Button(action: {
                            onSelect(team)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "person.3")
                                    .foregroundColor(.blue)
                                Text(team)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedTeam == team {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            loadTeams()
        }
    }
    
    func loadTeams() {
        guard let token = AuthManager.shared.token else { return }
        isLoading = true
        
        Task {
            do {
                teams = try await APIClient.shared.getTeams(token: token)
            } catch {
                print("Error loading teams: \(error)")
            }
            isLoading = false
        }
    }
}


struct EditingPreviewView: View {
    let message: Message
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.orange)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Editing message")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                Text(message.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}



struct ReplyPreviewView: View {
    let message: Message
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to \(message.user?.name ?? "Unknown")")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Text(message.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}
