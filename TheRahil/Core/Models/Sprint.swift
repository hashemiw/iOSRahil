//
//  Sprint.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//

import Foundation

struct Sprint: Identifiable, Codable {
    let id: UInt
    var projectID: UInt
    var name: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case name
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}
