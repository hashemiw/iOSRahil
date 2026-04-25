//
//  CreateProjectSheet.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//

// MARK: - Create Project Sheet

import SwiftUI

struct CreateProjectSheet: View {
    @Binding var isPresented: Bool
    let onProjectCreated: (Project) -> Void
    @EnvironmentObject var auth: AuthManager
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedTeam = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $name)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Team")) {
                    if auth.user?.role == "admin" {
                        TextField("Team Name", text: $selectedTeam)
                            .textInputAutocapitalization(.words)
                    } else if let team = auth.user?.team, !team.isEmpty {
                        HStack {
                            Text("Team")
                            Spacer()
                            Text(team)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        TextField("Team Name", text: $selectedTeam)
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
            .navigationTitle("New Project")
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
                        createProject()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(name.isEmpty || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func createProject() {
        Task {
            isSubmitting = true
            errorMessage = nil
            
            do {
                guard let token = auth.token else {
                    throw NSError(domain: "Auth", code: 401)
                }
                
                let team = auth.user?.role == "admin" ? selectedTeam : (auth.user?.team ?? selectedTeam)
                
                let newProject = try await APIClient.shared.createProject(
                    token: token,
                    name: name,
                    description: description,
                    team: team
                )
                
                await MainActor.run {
                    onProjectCreated(newProject)
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
