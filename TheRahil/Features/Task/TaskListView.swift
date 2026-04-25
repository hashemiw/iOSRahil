//
//  TaskListView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//

import SwiftUI
import Combine


struct TaskListView: View {
    let tasks: [Tasks]
    
    var body: some View {
        List {
            ForEach(groupedTasks.keys.sorted(), id: \.self) { status in
                Section(header: Text(sectionTitle(for: status))) {
                    ForEach(groupedTasks[status] ?? []) { task in
                        TaskListRow(task: task)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var groupedTasks: [String: [Tasks]] {
        Dictionary(grouping: tasks, by: { $0.status })
    }
    
    private func sectionTitle(for status: String) -> String {
        switch status {
        case "TODO": return "To Do"
        case "IN_PROGRESS": return "In Progress"
        case "DONE": return "Done"
        default: return status
        }
    }
}

struct TaskListRow: View {
    let task: Tasks
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: priorityIcon)
                .foregroundColor(priorityColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if let user = task.assignedUser {
                        Text(user.name ?? "Unassigned")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if let dueDate = task.dueDate {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(formatDate(dueDate))
                            .font(.caption)
                            .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            statusBadge
        }
        .padding(.vertical, 4)
    }
    
    private var statusBadge: some View {
        Text(task.status == "DONE" ? "Done" : (task.status == "IN_PROGRESS" ? "In Progress" : "To Do"))
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch task.status.uppercased() {
        case "DONE": return .green
        case "IN_PROGRESS": return .blue
        default: return .orange
        }
    }
    
    private var priorityIcon: String {
        switch task.priority.uppercased() {
        case "HIGH": return "exclamationmark.triangle.fill"
        case "LOW": return "arrow.down"
        default: return "minus.circle"
        }
    }
    
    private var priorityColor: Color {
        switch task.priority.uppercased() {
        case "HIGH": return .red
        case "LOW": return .gray
        default: return .orange
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        date < Date() && task.status != "DONE"
    }
}
