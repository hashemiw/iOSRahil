//
//  MyTaskResponse.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/14.
//

import Foundation


struct MyTaskResponse: Codable {
    let id: UInt
    let projectID: UInt
    let title: String
    let description: String
    let status: String
    let priority: String
    let assignedTo: UInt?
    let createdBy: UInt
    let dueDate: Date?
    let createdAt: Date
    let updatedAt: Date
    let project: ProjectInfo?
    let assignedUser: TaskUser?

    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case title, description, status, priority
        case assignedTo = "assigned_to"
        case createdBy = "created_by"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case project
        case assignedUser = "assigned_user"
    }
}

struct ProjectInfo: Codable {
    let id: UInt
    let name: String
    let description: String?
    let team: String?
    let companyID: UInt
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, team
        case companyID = "company_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
