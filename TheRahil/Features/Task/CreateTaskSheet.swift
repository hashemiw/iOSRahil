//
//  CreateTaskSheet.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//


import SwiftUI

struct CreateTaskSheet: View {
    @Binding var isPresented: Bool
    let projectId: UInt
    let members: [TaskUser]
    let onTaskCreated: (Tasks) -> Void
    @EnvironmentObject var auth: AuthManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority = "MEDIUM"
    @State private var selectedAssignee: UInt? = nil
    @State private var selectedStatus = "TODO"
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var hasDueDate = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    let priorities = ["LOW", "MEDIUM", "HIGH"]
    let statuses = ["TODO", "IN_PROGRESS", "DONE"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(priorities, id: \.self) { priority in
                            HStack {
                                Image(systemName: priorityIcon(for: priority))
                                Text(priority)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(statuses, id: \.self) { status in
                            Text(status == "TODO" ? "To Do" : (status == "IN_PROGRESS" ? "In Progress" : "Done"))
                                .tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Assign To")) {
                    if members.isEmpty {
                        Text("No team members available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Assignee", selection: $selectedAssignee) {
                            Text("Unassigned").tag(nil as UInt?)
                            ForEach(members) { member in
                                Text(member.name ?? member.email ?? "Unknown")
                                    .tag(member.id as UInt?)
                            }
                        }
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        createTask()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func priorityIcon(for priority: String) -> String {
        switch priority {
        case "HIGH": return "exclamationmark.triangle.fill"
        case "LOW": return "arrow.down"
        default: return "minus.circle"
        }
    }
    
    private func createTask() {
        Task {
            isSubmitting = true
            errorMessage = nil
            
            do {
                guard let token = auth.token else {
                    throw NSError(domain: "Auth", code: 401)
                }
                
                let newTask = try await APIClient.shared.createTask(
                    token: token,
                    projectId: projectId,
                    title: title,
                    description: description,
                    status: selectedStatus,
                    priority: selectedPriority,
                    assignedTo: selectedAssignee,
                    dueDate: hasDueDate ? dueDate : nil
                )
                
                await MainActor.run {
                    onTaskCreated(newTask)
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
}
