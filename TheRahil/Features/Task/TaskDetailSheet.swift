//
//  TaskDetailSheet.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//


import SwiftUI

struct TaskDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthManager
    
    let task: Tasks
    let projectId: UInt
    
    @State private var selectedStatus: String
    @State private var selectedPriority: String
    @State private var selectedAssignee: UInt?
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var isSubmitting = false
    @State private var showDeleteConfirmation = false
    
    init(task: Tasks, projectId: UInt) {
        self.task = task
        self.projectId = projectId
        self._selectedStatus = State(initialValue: task.status)
        self._selectedPriority = State(initialValue: task.priority)
        self._selectedAssignee = State(initialValue: task.assignedTo)
        self._dueDate = State(initialValue: task.dueDate)
        self._hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Title")) {
                    Text(task.title)
                        .font(.headline)
                }
                
                if !task.description.isEmpty {
                    Section(header: Text("Description")) {
                        Text(task.description)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        Text("To Do").tag("TODO")
                        Text("In Progress").tag("IN_PROGRESS")
                        Text("Done").tag("DONE")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedStatus) { _ in
                        saveChanges()
                    }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $selectedPriority) {
                        Text("Low").tag("LOW")
                        Text("Medium").tag("MEDIUM")
                        Text("High").tag("HIGH")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedPriority) { _ in
                        saveChanges()
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                        .onChange(of: hasDueDate) { _ in
                            if hasDueDate && dueDate == nil {
                                dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
                            }
                            saveChanges()
                        }
                    
                    if hasDueDate, let date = dueDate {
                        DatePicker("Due Date", selection: Binding(
                            get: { date },
                            set: { newDate in
                                dueDate = newDate
                                saveChanges()
                            }
                        ), in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    }
                }
                
                Section(header: Text("Created")) {
                    HStack {
                        Text("By")
                        Spacer()
                        Text("User #\(task.createdBy)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("On")
                        Spacer()
                        Text(formatDate(task.createdAt))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Task")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete Task?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private func saveChanges() {
        guard !isSubmitting else { return }
        
        Task {
            isSubmitting = true
            
            do {
                guard let token = auth.token else { return }
                
                _ = try await APIClient.shared.updateTask(
                    token: token,
                    projectId: projectId,
                    taskId: task.id,
                    title: nil,
                    description: nil,
                    status: selectedStatus,
                    priority: selectedPriority,
                    assignedTo: selectedAssignee,
                    dueDate: hasDueDate ? dueDate : nil
                )
            } catch {
                print("Error updating task: \(error)")
            }
            
            isSubmitting = false
        }
    }
    
    private func deleteTask() {
        Task {
            do {
                guard let token = auth.token else { return }
                
                _ = try await APIClient.shared.deleteTask(
                    token: token,
                    projectId: projectId,
                    taskId: task.id
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
