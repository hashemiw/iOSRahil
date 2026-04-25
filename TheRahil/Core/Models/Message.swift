//
//  Message.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/6.
//

import Foundation


struct Message: Identifiable, Codable, Equatable {
    let id: UInt
    let team: String
    let userID: UInt
    let user: MessageUser?
    let content: String
    let createdAt: Date
    let messageType: MessageType?
    let fileURL: String?
    let fileName: String?
    let fileSize: Int64?
    let thumbnailURL: String?
    let duration: Int?
    let replyToID: UInt?
    let replyTo: ReplyPreview?
    let isEdited: Bool?
    var reactions: [MessageReaction]?

    enum CodingKeys: String, CodingKey {
        case id, team
        case userID = "user_id"
        case user, content
        case createdAt = "created_at"
        case messageType = "message_type"
        case fileURL = "file_url"
        case fileName = "file_name"
        case fileSize = "file_size"
        case thumbnailURL = "thumbnail_url"
        case duration
        case replyToID = "reply_to_id"
        case replyTo = "reply_to"
        case isEdited = "is_edited"
        case reactions
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
    
    var displayDuration: Int {
        duration ?? 0
    }
}


enum MessageType: String, Codable {
    case text
    case image
    case video
    case audio
    case file
}


struct MessageReaction: Identifiable, Codable {
    let id: UInt
    let messageID: UInt
    let userID: UInt
    let emoji: String
    let createdAt: Date
    let user: MessageUser?

    enum CodingKeys: String, CodingKey {
        case id
        case messageID = "message_id"
        case userID = "user_id"
        case emoji
        case createdAt = "created_at"
        case user
    }
}

struct MessageUser: Codable, Equatable {
    let id: UInt
    let name: String?
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case imageURL = "image_url"
    }
}

struct ReplyPreview: Codable, Equatable {
    let id: UInt
    let content: String
    let user: MessageUser?
    
}
