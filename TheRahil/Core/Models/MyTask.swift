//
//  MyTask.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//

import Foundation

struct MyTask: Identifiable, Codable {
    let id: UInt
    let projectID: UInt
    let projectName: String
    let title: String
    let status: String
    let priority: String
    let dueDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case projectName = "project_name"
        case title, status, priority
        case dueDate = "due_date"
    }
}
