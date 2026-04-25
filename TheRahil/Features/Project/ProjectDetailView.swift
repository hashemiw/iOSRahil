//
//  ProjectDetailView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//


import SwiftUI
import Combine


struct ProjectDetailView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var viewModel: ProjectDetailViewModel
    @State private var selectedTab: ProjectTab = .board
    @State private var showCreateTask = false
    @State private var showCreateSprint = false
    
    let project: Project
    
    enum ProjectTab: String, CaseIterable {
        case board = "Board"
        case list = "List"
        case overview = "Overview"
        
        var icon: String {
            switch self {
            case .board: return "square.grid.3x3"
            case .list: return "list.bullet"
            case .overview: return "info.circle"
            }
        }
    }
    
    init(project: Project) {
        self.project = project
        self._viewModel = StateObject(wrappedValue: ProjectDetailViewModel(projectId: project.id))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(ProjectTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Group {
                    switch selectedTab {
                    case .board:
                        KanbanBoardView(
                            tasks: viewModel.tasks,
                            onTaskMove: { taskId, newStatus in
                                Task {
                                    await viewModel.updateTaskStatus(taskId: taskId, status: newStatus, token: auth.token!)
                                }
                            },
                            onTaskTap: { task in
                                viewModel.selectedTask = task
                            }
                        )
                    case .list:
                        TaskListView(tasks: viewModel.tasks)
                    case .overview:
                        ProjectOverviewView(project: project)
                    }
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showCreateTask = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showCreateSprint = true
                    } label: {
                        Label("New Sprint", systemImage: "bolt.fill")
                    }
                    
                    Button {
                        Task {
                            await viewModel.loadTasks(token: auth.token!)
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showCreateTask) {
            CreateTaskSheet(
                isPresented: $showCreateTask,
                projectId: project.id,
                members: viewModel.members
            ) { newTask in
                viewModel.tasks.append(newTask)
            }
            .environmentObject(auth)
        }
        .sheet(isPresented: $showCreateSprint) {
            CreateSprintSheet(isPresented: $showCreateSprint, projectId: project.id) { _ in
            }
        }
        .sheet(item: $viewModel.selectedTask) { task in
            TaskDetailSheet(task: task, projectId: project.id)
        }
        .onAppear {
            if let token = auth.token {
                Task {
                    await viewModel.loadTasks(token: token)
                    await viewModel.loadMembers(token: token)
                }
            }
        }
    }
}


@MainActor
final class ProjectDetailViewModel: ObservableObject {
    @Published var tasks: [Tasks] = []
    @Published var members: [TaskUser] = []
    @Published var selectedTask: Tasks? = nil
    @Published var isLoading = false
    
    let projectId: UInt
    
    init(projectId: UInt) {
        self.projectId = projectId
    }
    
    func loadTasks(token: String) async {
        isLoading = true
        do {
            tasks = try await APIClient.shared.getTasks(token: token, projectId: projectId)
        } catch {
            print("Error loading tasks: \(error)")
        }
        isLoading = false
    }
    
    func loadMembers(token: String) async {
        do {
            members = try await APIClient.shared.getProjectMembers(token: token, projectId: projectId)
        } catch {
            print("Error loading members: \(error)")
        }
    }
    
    func updateTaskStatus(taskId: UInt, status: String, token: String) async {
        do {
            _ = try await APIClient.shared.updateTask(
                token: token,
                projectId: projectId,
                taskId: taskId,
                title: nil,
                description: nil,
                status: status,
                priority: nil,
                assignedTo: nil,
                dueDate: nil
            )
            await loadTasks(token: token)
        } catch {
            print("Error updating task: \(error)")
        }
    }
}
