//
//  Request.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/20.
//

import Foundation

struct Request: Identifiable, Codable {
    let id: UInt
    let type: String
    let reason: String
    let status: String
    let date: Date
    let createdAt: Date
    let userID: UInt
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case reason
        case status
        case date
        case createdAt = "created_at"
        case userID = "user_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UInt.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        reason = try container.decode(String.self, forKey: .reason)
        status = try container.decode(String.self, forKey: .status)
        date = try container.decode(Date.self, forKey: .date)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        userID = try container.decodeIfPresent(UInt.self, forKey: .userID) ?? 0
    }
}
