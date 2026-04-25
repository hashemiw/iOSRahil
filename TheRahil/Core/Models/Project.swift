//
//  Project.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//

import SwiftUI
import Foundation


struct Project: Identifiable, Codable {
    let id: UInt
    var name: String
    var description: String
    var companyID: UInt
    var team: String
    var createdBy: UInt
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case companyID = "company_id"
        case team
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
