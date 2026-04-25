// MARK: - Updated HomeView with Dashboard

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var viewModel = HomeViewModel()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                welcomeHeader
                
                LazyVGrid(columns: columns, spacing: 16) {
                    DashboardCard(
                        title: "My Tasks",
                        icon: "checklist",
                        color: .blue,
                        count: viewModel.myTasksCount,
                        action: { viewModel.showMyTasks = true }
                    )
                    
                    DashboardCard(
                        title: "Attendance",
                        icon: "clock.fill",
                        color: .green,
                        subtitle: viewModel.attendanceStatus,
                        action: { viewModel.showAttendance = true }
                    )
                    
                    DashboardCard(
                        title: "Requests",
                        icon: "doc.text.fill",
                        color: .orange,
                        count: viewModel.pendingRequestsCount,
                        action: { viewModel.showRequests = true }
                    )
                    
                    DashboardCard(
                        title: "Messages",
                        icon: "message.fill",
                        color: .purple,
                        count: viewModel.unreadMessagesCount,
                        action: { viewModel.showMessages = true }
                    )
                }
                .padding(.horizontal)
                
                quickActionsSection
                
                if !viewModel.recentTasks.isEmpty {
                    recentTasksSection
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.loadDashboardData(token: auth.token!)
        }
        .onAppear {
            if let token = auth.token {
                Task {
                    await viewModel.loadDashboardData(token: token)
                }
            }
        }
        .sheet(isPresented: $viewModel.showMyTasks) {
            NavigationStack {
                MyTasksListView()
            }
        }
        .sheet(isPresented: $viewModel.showAttendance) {
            NavigationStack {
                AttendanceView()
            }
        }
        .sheet(isPresented: $viewModel.showNewRequest) {
            NavigationStack {
                NewRequestSheet(isPresented: $viewModel.showNewRequest) { newRequest in
                }
                .environmentObject(auth)
            }
        }
        .sheet(isPresented: $viewModel.showNewTask) {
            NavigationStack {
                SelectProjectForTaskSheet(isPresented: $viewModel.showNewTask)
                    .environmentObject(auth)
            }
        }
        .navigationDestination(isPresented: $viewModel.showRequests) {
            RequestsView()
        }
        .navigationDestination(isPresented: $viewModel.showMessages) {
            TeamMessagesView()
        }
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(auth.user?.name ?? "User")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            Text(getRandomQuote())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "New Request",
                    icon: "plus.circle.fill",
                    color: .orange
                ) {
                    viewModel.showNewRequest = true
                }
                QuickActionButton(
                    title: "New Task",
                    icon: "checkmark.circle.fill",
                    color: .blue
                ) {
                    viewModel.showNewTask = true
                }
            }
            .padding(.horizontal)
        }
    }

    private var recentTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Tasks")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    viewModel.showMyTasks = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(viewModel.recentTasks.prefix(3)) { task in
                    RecentTaskRow(task: task)
                }
            }
            .padding(.horizontal)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning 🌅" }
        else if hour < 17 { return "Good Afternoon ☀️" }
        else { return "Good Evening 🌙" }
    }

    private func getRandomQuote() -> String {
        let quotes = [
            "Make today amazing!",
            "Your potential is endless.",
            "Focus on the good.",
            "Dream big, work hard."
        ]
        return quotes.randomElement() ?? "Have a great day!"
    }
}

struct DashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    var count: Int? = nil
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                    if let count = count, count > 0 {
                        Text("\(count)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color)
                            .clipShape(Capsule())
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let count = count {
                        Text("\(count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentTaskRow: View {
    let task: MyTask

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(task.projectName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: priorityIcon)
                .foregroundColor(priorityColor)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
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
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var myTasksCount: Int = 0
    @Published var attendanceStatus: String = "Not checked in"
    @Published var pendingRequestsCount: Int = 0
    @Published var unreadMessagesCount: Int = 0
    @Published var recentTasks: [MyTask] = []
    
    @Published var showMyTasks = false
    @Published var showAttendance = false
    @Published var showRequests = false
    @Published var showMessages = false
    @Published var showNewRequest = false
    @Published var showNewTask = false

    func loadDashboardData(token: String) async {
        print("🔵 [HomeVM] loadDashboardData started")
        
        do {
            let tasks = try await APIClient.shared.getMyTasks(token: token)
            print("🟢 [HomeVM] getMyTasks success: \(tasks.count) tasks")
            myTasksCount = tasks.count
            recentTasks = tasks
        } catch {
            print("🔴 [HomeVM] getMyTasks error: \(error)")
        }
        
        do {
            let requests = try await APIClient.shared.getRequests(token: token)
            pendingRequestsCount = requests.filter { $0.status == "PENDING" }.count
        } catch {
            print("Error loading requests: \(error)")
        }
        
        do {
            let messages = try await APIClient.shared.getMessages(token: token)
            unreadMessagesCount = messages.count
        } catch {
            print("Error loading messages: \(error)")
        }
        
        if let lastStatus = AuthManager.shared.user?.lastStatus {
            attendanceStatus = lastStatus == "IN" ? "Checked In" : "Checked Out"
        }
    }

    func checkIn(token: String) async {
        guard let deviceID = DeviceManager.shared.deviceID else { return }
        do {
            try await APIClient.shared.request(
                path: "/api/attendance",
                method: "POST",
                token: token,
                body: [
                    "type": "IN",
                    "deviceID": deviceID,
                    "lat": 35.6892,
                    "lng": 51.3890
                ]
            )
            attendanceStatus = "Checked In"
            await AuthManager.shared.fetchProfile(token: token)
        } catch {
            print("Check in error: \(error)")
        }
    }
}
