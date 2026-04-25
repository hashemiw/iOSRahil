//
//  ProjectsListView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//


import SwiftUI
import Combine


struct ProjectsListView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showCreateProject = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.projects.isEmpty {
                ProgressView("Loading Projects...")
            } else if viewModel.projects.isEmpty {
                emptyStateView
            } else {
                projectsList
            }
        }
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateProject = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Button("All Projects") {
                        viewModel.filterByTeam(nil)
                    }
                    ForEach(viewModel.availableTeams, id: \.self) { team in
                        Button(team) {
                            viewModel.filterByTeam(team)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedTeam ?? "All")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadProjects(token: auth.token!)
        }
        .onAppear {
            if viewModel.projects.isEmpty, let token = auth.token {
                Task {
                    await viewModel.loadProjects(token: token)
                }
            }
        }
        .sheet(isPresented: $showCreateProject) {
            CreateProjectSheet(isPresented: $showCreateProject) { newProject in
                viewModel.projects.insert(newProject, at: 0)
            }
            .environmentObject(auth)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
    
    private var projectsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.projects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        ProjectCard(project: project)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Projects Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first project to start managing tasks")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showCreateProject = true
            } label: {
                Label("Create Project", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}


struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !project.team.isEmpty {
                        Text(project.team)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(formatDate(project.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedTeam: String? = nil
    @Published var availableTeams: [String] = []
    
    func loadProjects(token: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            projects = try await APIClient.shared.getProjects(token: token, team: selectedTeam)
            
            let teams = Set(projects.map { $0.team }.filter { !$0.isEmpty })
            availableTeams = Array(teams).sorted()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func filterByTeam(_ team: String?) {
        selectedTeam = team
        if let token = AuthManager.shared.token {
            Task {
                await loadProjects(token: token)
            }
        }
    }
}
