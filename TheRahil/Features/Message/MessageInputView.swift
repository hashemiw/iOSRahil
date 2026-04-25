//
//  MessageInputView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/17.
//

import SwiftUI



struct MessageInputView: View {
    @ObservedObject var viewModel: MessagesViewModel
    @ObservedObject var audioRecorder: AudioRecorderManager
    @ObservedObject var audioPlayer: AudioPlayerManager
    let onAttachmentTap: () -> Void
    let onRecordTap: () -> Void
    let isRecording: Bool
    let auth: AuthManager

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)

            VStack(spacing: 8) {
                if let replying = viewModel.replyingTo {
                    HStack {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .foregroundColor(.blue)
                        Text("Reply to: \(replying.content.prefix(30))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Button(action: { viewModel.cancelReplyOrEdit() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                if let editing = viewModel.editingMessage {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.orange)
                        Text("Editing: \(editing.content.prefix(30))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Button(action: { viewModel.cancelReplyOrEdit() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                HStack(spacing: 12) {
                    Button(action: onAttachmentTap) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }

                    HStack {
                        TextField(
                            viewModel.editingMessage != nil ? "Edit message..." : "Type a message...",
                            text: $viewModel.newMessageText,
                            axis: .vertical
                        )
                        .focused($isFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .lineLimit(1...5)

                        Button(action: onRecordTap) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(isRecording ? .red : .blue)
                                .scaleEffect(isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                        }
                    }

                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(sendButtonColor)
                                .frame(width: 44, height: 44)

                            if viewModel.isSending || viewModel.isUploading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: viewModel.editingMessage != nil ? "checkmark" : "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if viewModel.isUploading {
                    VStack(spacing: 4) {
                        ProgressView(value: viewModel.uploadProgress)
                            .tint(.blue)
                        Text("Uploading...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                if isRecording {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text(formatRecordingTime(audioRecorder.recordingDuration))
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Recording...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Tap stop to send")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
    }

    private var canSend: Bool {
        let hasText = !viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isNotSending = !viewModel.isSending && !viewModel.isUploading
        return hasText && isNotSending
    }

    private var sendButtonColor: Color {
        canSend ? .blue : .gray.opacity(0.3)
    }

    private func sendMessage() {
        Task {
            if viewModel.editingMessage != nil {
                await viewModel.editMessage(
                    token: auth.token!,
                    message: viewModel.editingMessage!,
                    newContent: viewModel.newMessageText
                )
            } else {
                await viewModel.sendMessage(token: auth.token!)
            }
        }
    }

    private func formatRecordingTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
