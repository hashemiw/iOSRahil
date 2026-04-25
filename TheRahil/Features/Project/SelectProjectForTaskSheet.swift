//
//  SelectProjectForTaskSheet.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/14.
//

import SwiftUI

struct SelectProjectForTaskSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var auth: AuthManager
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var selectedProject: Project?
    @State private var showCreateTask = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.projects.isEmpty {
                    ProgressView("Loading Projects...")
                } else if viewModel.projects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No projects available")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.projects) { project in
                        Button {
                            selectedProject = project
                            showCreateTask = true
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(project.name)
                                        .foregroundColor(.primary)
                                    if !project.team.isEmpty {
                                        Text(project.team)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                if let token = auth.token {
                    Task {
                        await viewModel.loadProjects(token: token)
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                if let project = selectedProject {
                    CreateTaskSheet(
                        isPresented: $showCreateTask,
                        projectId: project.id,
                        members: []
                    ) { newTask in
                        isPresented = false
                    }
                    .environmentObject(auth)
                }
            }
        }
    }
}
