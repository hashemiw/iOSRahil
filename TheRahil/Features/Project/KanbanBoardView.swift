//
//  KanbanBoardView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//


import SwiftUI
import Combine


struct KanbanBoardView: View {
    let tasks: [Tasks]
    let onTaskMove: (UInt, String) -> Void
    let onTaskTap: (Tasks) -> Void
    
    private let columns = ["TODO", "IN_PROGRESS", "DONE"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(columns, id: \.self) { status in
                    KanbanColumn(
                        title: columnTitle(for: status),
                        icon: columnIcon(for: status),
                        color: columnColor(for: status),
                        tasks: tasks.filter { $0.status == status },
                        onTaskMove: onTaskMove,
                        onTaskTap: onTaskTap
                    )
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func columnTitle(for status: String) -> String {
        switch status {
        case "TODO": return "To Do"
        case "IN_PROGRESS": return "In Progress"
        case "DONE": return "Done"
        default: return status
        }
    }
    
    private func columnIcon(for status: String) -> String {
        switch status {
        case "TODO": return "circle"
        case "IN_PROGRESS": return "arrow.right.circle"
        case "DONE": return "checkmark.circle.fill"
        default: return "circle"
        }
    }
    
    private func columnColor(for status: String) -> Color {
        switch status {
        case "TODO": return .orange
        case "IN_PROGRESS": return .blue
        case "DONE": return .green
        default: return .gray
        }
    }
}

struct KanbanColumn: View {
    let title: String
    let icon: String
    let color: Color
    let tasks: [Tasks]
    let onTaskMove: (UInt, String) -> Void
    let onTaskTap: (Tasks) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        KanbanTaskCard(task: task)
                            .onTapGesture {
                                onTaskTap(task)
                            }
                            .contextMenu {
                                if task.status != "TODO" {
                                    Button {
                                        onTaskMove(task.id, "TODO")
                                    } label: {
                                        Label("Move to To Do", systemImage: "circle")
                                    }
                                }
                                if task.status != "IN_PROGRESS" {
                                    Button {
                                        onTaskMove(task.id, "IN_PROGRESS")
                                    } label: {
                                        Label("Move to In Progress", systemImage: "arrow.right.circle")
                                    }
                                }
                                if task.status != "DONE" {
                                    Button {
                                        onTaskMove(task.id, "DONE")
                                    } label: {
                                        Label("Move to Done", systemImage: "checkmark.circle")
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 280)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}


struct KanbanTaskCard: View {
    let task: Tasks
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: priorityIcon)
                    .foregroundColor(priorityColor)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)
                
                Text(task.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            HStack(spacing: 8) {
                if let user = task.assignedUser {
                    HStack(spacing: 4) {
                        if let imageURL = user.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text(user.name ?? "Unassigned")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Unassigned")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(formatDate(dueDate))
                            .font(.caption2)
                    }
                    .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isOverdue(dueDate) ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            
            if task.priority != "MEDIUM" {
                HStack(spacing: 4) {
                    Image(systemName: priorityIcon)
                        .font(.system(size: 10))
                    Text(priorityLabel)
                        .font(.caption2.bold())
                }
                .foregroundColor(priorityColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(priorityColor.opacity(0.15))
                .cornerRadius(4)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(task.status == "DONE" ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    
    private var priorityIcon: String {
        switch task.priority.uppercased() {
        case "HIGH":
            return "exclamationmark.triangle.fill"
        case "LOW":
            return "arrow.down"
        default:
            return "minus.circle.fill"
        }
    }
    
    private var priorityColor: Color {
        switch task.priority.uppercased() {
        case "HIGH":
            return .red
        case "LOW":
            return .gray
        default:
            return .orange
        }
    }
    
    private var priorityLabel: String {
        switch task.priority.uppercased() {
        case "HIGH":
            return "High"
        case "LOW":
            return "Low"
        default:
            return "Medium"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if let daysDiff = calendar.dateComponents([.day], from: now, to: date).day, daysDiff < 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        date < Date() && task.status != "DONE"
    }
}
