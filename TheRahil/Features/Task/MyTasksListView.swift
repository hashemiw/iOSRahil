//
//  MyTasksListView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//


import SwiftUI
import Combine


struct MyTasksListView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MyTasksViewModel()
    @State private var selectedFilter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case todo = "To Do"
        case inProgress = "In Progress"
        case done = "Done"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            if viewModel.isLoading && viewModel.tasks.isEmpty {
                Spacer()
                ProgressView("Loading tasks...")
                Spacer()
            } else if filteredTasks.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "checklist")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No tasks found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(groupedTasks.keys.sorted(), id: \.self) { projectName in
                        Section(header: Text(projectName)) {
                            ForEach(groupedTasks[projectName] ?? []) { task in
                                MyTaskRow(task: task)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("My Tasks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .refreshable {
            await viewModel.loadTasks(token: auth.token!)
        }
        .onAppear {
            if viewModel.tasks.isEmpty, let token = auth.token {
                Task {
                    await viewModel.loadTasks(token: token)
                }
            }
        }
    }
    
    private var filteredTasks: [MyTask] {
        switch selectedFilter {
        case .all:
            return viewModel.tasks
        case .todo:
            return viewModel.tasks.filter { $0.status == "TODO" }
        case .inProgress:
            return viewModel.tasks.filter { $0.status == "IN_PROGRESS" }
        case .done:
            return viewModel.tasks.filter { $0.status == "DONE" }
        }
    }
    
    private var groupedTasks: [String: [MyTask]] {
        Dictionary(grouping: filteredTasks, by: { $0.projectName })
    }
}

struct MyTaskRow: View {
    let task: MyTask
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    priorityBadge
                    
                    if let dueDate = task.dueDate {
                        Text("•")
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(formatDate(dueDate))
                        }
                        .font(.caption)
                        .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch task.status.uppercased() {
        case "DONE": return "checkmark.circle.fill"
        case "IN_PROGRESS": return "arrow.right.circle.fill"
        default: return "circle"
        }
    }
    
    private var statusColor: Color {
        switch task.status.uppercased() {
        case "DONE": return .green
        case "IN_PROGRESS": return .blue
        default: return .orange
        }
    }
    
    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: priorityIcon)
            Text(task.priority)
        }
        .font(.caption)
        .foregroundColor(priorityColor)
    }
    
    private var priorityIcon: String {
        switch task.priority.uppercased() {
        case "HIGH": return "exclamationmark.triangle.fill"
        case "LOW": return "arrow.down"
        default: return "minus"
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


@MainActor
final class MyTasksViewModel: ObservableObject {
    @Published var tasks: [MyTask] = []
    @Published var isLoading = false
    
    func loadTasks(token: String) async {
        isLoading = true
        
        do {
            tasks = try await APIClient.shared.getMyTasks(token: token)
        } catch {
            print("Error loading my tasks: \(error)")
            await loadTasksFromProjects(token: token)
        }
        
        isLoading = false
    }
    
    private func loadTasksFromProjects(token: String) async {
        do {
            let projects = try await APIClient.shared.getProjects(token: token)
            var allTasks: [MyTask] = []
            
            for project in projects {
                let tasks = try await APIClient.shared.getTasks(token: token, projectId: project.id)
                for task in tasks where task.assignedTo != nil {
                }
            }
        } catch {
            print("Error loading tasks from projects: \(error)")
        }
    }
}
