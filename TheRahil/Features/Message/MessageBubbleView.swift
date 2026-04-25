//
//  MessageBubbleView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/17.
//

import SwiftUI


struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    let audioPlayer: AudioPlayerManager
    let onReply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReaction: (String) -> Void
    let auth: AuthManager
    let viewModel: MessagesViewModel

    @State private var showActionSheet = false

    private let reactionEmojis = ["👍", "❤️", "😂", "😮", "😢", "🙏", "🎉", "🔥"]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser { Spacer() }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.user?.name ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let replyTo = message.replyTo {
                    ReplyBubble(replyPreview: replyTo, isCurrentUser: isCurrentUser)
                }

                messageContent

                if let reactions = message.reactions, !reactions.isEmpty {
                    ReactionsView(
                        reactions: reactions,
                        currentUserID: auth.user?.id,
                        onReaction: onReaction
                    )
                }

                HStack(spacing: 4) {
                    Text(formatTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if message.isEdited == true {
                        Text("(edited)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .onLongPressGesture {
                showActionSheet = true
            }

            if !isCurrentUser { Spacer() }
        }
        .confirmationDialog("Actions", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("Reply") { onReply() }

            if message.userID == auth.user?.id {
                Button("Edit") { onEdit() }
                Button("Delete", role: .destructive) { onDelete() }
            }

            Button("Add Reaction") {
                Task {
                    await viewModel.toggleReaction(token: auth.token!, message: message, emoji: "👍")
                }
            }

            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var messageContent: some View {
        switch message.messageType {
        case .image:
            imagePreview

        case .video:
            videoPreview

        case .audio:
            AudioPlayerView(
                message: message,
                audioPlayer: audioPlayer
            )

        case .file:
            FileAttachmentView(
                fileName: message.fileName,
                fileSize: message.fileSize,
                fileURL: message.fileURL,
                isCurrentUser: isCurrentUser
            )

        default:
            textBubble
        }
    }

    private var textBubble: some View {
        Text(message.content)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubbleColor)
            .foregroundColor(isCurrentUser ? .white : .primary)
            .cornerRadius(18)
    }

    private var bubbleColor: Color {
        isCurrentUser ? .blue : Color(.systemGray5)
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let fileURLString = message.fileURL,
           let url = URL(string: fileURLString) {
            
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 200, height: 200)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(12)
                case .failure:
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(fileURLString)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }
                    .frame(width: 200, height: 200)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                @unknown default:
                    EmptyView()
                }
            }
            .onAppear {
                print("🟢 Image URL: \(fileURLString)")
            }

            if !message.content.isEmpty {
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(12)
            }
        } else {
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("No image URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 200, height: 100)
        }
    }

    @ViewBuilder
    private var videoPreview: some View {
        ZStack {
            if let fileURLString = message.fileURL,
               let url = URL(string: fileURLString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.black)
                }
            } else {
                Rectangle()
                    .fill(Color.black)
            }

            Image(systemName: "play.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
        .frame(width: 200, height: 150)
        .cornerRadius(12)
        .onTapGesture {
            if let urlString = message.fileURL, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }

        if !message.content.isEmpty {
            Text(message.content)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(bubbleColor)
                .foregroundColor(isCurrentUser ? .white : .primary)
                .cornerRadius(12)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}


struct AudioPlayerView: View {
    let message: Message
    @ObservedObject var audioPlayer: AudioPlayerManager

    var body: some View {
        HStack(spacing: 12) {
            Button(action: playAudio) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isPlaying ? Color.blue : Color.blue.opacity(0.5))
                            .frame(width: 3, height: waveHeight(for: index))
                    }
                }

                Text(formatDuration(displayDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
        .frame(maxWidth: 200)
    }

    private var displayDuration: Int {
        if let dur = message.duration, dur > 0 {
            return dur
        }
        return 1
    }

    private var isPlaying: Bool {
        audioPlayer.isPlaying && audioPlayer.currentMessageID == message.id
    }

    private func playAudio() {
        guard let urlString = message.fileURL,
              let url = URL(string: urlString, relativeTo: baseURL) else {
            print("❌ Invalid audio URL: \(message.fileURL ?? "nil")")
            return
        }
        
        print("🎵 Playing audio from: \(url)")

        if isPlaying {
            audioPlayer.stop()
        } else {
            audioPlayer.play(url: url, messageID: message.id)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func waveHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [12, 18, 24, 16, 20, 14, 22, 18, 10, 24, 14, 20, 16, 22, 12, 18, 24, 16, 20, 14]
        return heights[index % heights.count]
    }
}

private let baseURL = URL(string: "http://localhost:8080")!

struct FileAttachmentView: View {
    let fileName: String?
    let fileSize: Int64?
    let fileURL: String?
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            fileIcon
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(fileName ?? "File")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(isCurrentUser ? .white : .primary)

                if let size = fileSize {
                    Text(formatFileSize(size))
                        .font(.caption)
                        .foregroundColor(isCurrentUser ? .white.opacity(0.7) : .secondary)
                }
            }

            Spacer()

            Image(systemName: "arrow.down.circle")
                .font(.system(size: 24))
                .foregroundColor(isCurrentUser ? .white : .blue)
        }
        .padding()
        .background(isCurrentUser ? Color.blue.opacity(0.8) : Color(.systemGray5))
        .cornerRadius(12)
        .frame(maxWidth: 200)
        .onTapGesture {
            if let urlString = fileURL, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }

    @ViewBuilder
    private var fileIcon: some View {
        let ext = (fileName ?? "").split(separator: ".").last?.lowercased() ?? ""

        switch ext {
        case "pdf":
            Image(systemName: "doc.fill")
                .foregroundColor(.red)
        case "xlsx", "xls", "csv":
            Image(systemName: "tablecells")
                .foregroundColor(.green)
        case "doc", "docx":
            Image(systemName: "doc.text.fill")
                .foregroundColor(.blue)
        default:
            Image(systemName: "doc.fill")
                .foregroundColor(isCurrentUser ? .white : .gray)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct ReactionsView: View {
    let reactions: [MessageReaction]
    let currentUserID: UInt?
    let onReaction: (String) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(groupedReactions, id: \.emoji) { group in
                ReactionBadge(
                    count: group.count,
                    emoji: group.emoji,
                    hasReacted: group.users.contains { $0 == currentUserID },
                    onTap: { onReaction(group.emoji) }
                )
            }
        }
    }

    private var groupedReactions: [(emoji: String, count: Int, users: [UInt])] {
        var grouped: [String: (count: Int, users: [UInt])] = [:]
        for reaction in reactions {
            var entry = grouped[reaction.emoji] ?? (count: 0, users: [])
            entry.count += 1
            entry.users.append(reaction.userID)
            grouped[reaction.emoji] = entry
        }
        return grouped.map { (emoji: $0.key, count: $0.value.count, users: $0.value.users) }
            .sorted { $0.count > $1.count }
    }
}

struct ReactionBadge: View {
    let count: Int
    let emoji: String
    let hasReacted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.caption)
                if count > 1 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(hasReacted ? .blue : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(hasReacted ? Color.blue.opacity(0.2) : Color(.systemGray5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasReacted ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct ReplyBubble: View {
    let replyPreview: ReplyPreview
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(isCurrentUser ? Color.white.opacity(0.5) : Color.blue.opacity(0.5))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(replyPreview.user?.name ?? "Unknown")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentUser ? .white.opacity(0.8) : .blue)

                Text(replyPreview.content)
                    .font(.caption2)
                    .foregroundColor(isCurrentUser ? .white.opacity(0.7) : .secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isCurrentUser ? Color.blue.opacity(0.3) : Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct FileMessageView: View {
    let message: Message
    let isCurrentUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch message.messageType {
            case .image:
                if let fileURL = message.fileURL {
                    AsyncImage(url: URL(string: fileURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                    }
                    .frame(maxWidth: 200, maxHeight: 200)
                    .cornerRadius(12)
                }

            case .video:
                VideoPreviewView(url: message.fileURL)
                    .frame(width: 200, height: 150)
                    .cornerRadius(12)

            case .audio:
                AudioMessageView(url: message.fileURL, duration: message.duration)
                    .frame(maxWidth: 200)

            case .file:
                    FileAttachmentView(fileName: message.fileName, fileSize: message.fileSize, fileURL: message.fileURL, isCurrentUser: true)
                    .frame(maxWidth: 200)

            default:
                EmptyView()
            }

            if !message.content.isEmpty {
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(12)
            }
        }
    }
}

struct AudioMessageView: View {
    let url: String?
    let duration: Int?

    @State private var isPlaying = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { isPlaying.toggle() }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.5))
                            .frame(width: 3, height: CGFloat.random(in: 8...24))
                    }
                }

                Text(formatDuration(duration ?? 0))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}


struct VideoPreviewView: View {
    let url: String?

    var body: some View {
        ZStack {
            if let urlString = url, let videoURL = URL(string: urlString) {
                AsyncImage(url: videoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.black)
                }

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            } else {
                Rectangle()
                    .fill(Color.black)
                Image(systemName: "video")
                    .foregroundColor(.white)
            }
        }
    }
}
