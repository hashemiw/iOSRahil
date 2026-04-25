//
//  TaskUser.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//

import Foundation


struct TaskUser: Codable, Identifiable {
    let id: UInt
    let name: String?
    let email: String?
    let imageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case imageURL = "image_url"
    }
}
