//
//  Task.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//

import SwiftUI
import Foundation

struct Tasks: Identifiable, Codable {
    let id: UInt
    var projectID: UInt
    var title: String
    var description: String
    var status: String 
    var priority: String
    var assignedTo: UInt?
    var assignedUser: TaskUser?
    var createdBy: UInt
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case title, description, status, priority
        case assignedTo = "assigned_to"
        case assignedUser = "assigned_user"
        case createdBy = "created_by"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
