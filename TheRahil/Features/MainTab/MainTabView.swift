//
// MainTabView.swift
// TheRahil
//
// Created by Alireza Hashemi on 2026/1/14.
//


import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var selectedTab: Tab = .home
    @State private var showLogoutAlert = false
    
    enum Tab: CaseIterable {
        case home, attendance, projects, requests, messages
        
        var title: String {
            switch self {
                case .home: return "Home"
                case .attendance: return "Attendance"
                case .projects: return "Projects"
                case .requests: return "Requests"
                case .messages: return "Messages"
            }
        }
        
        var icon: String {
            switch self {
                case .home: return "house.fill"
                case .attendance: return "clock.fill"
                case .projects: return "folder.fill"
                case .requests: return "list.bullet.rectangle"
                case .messages: return "message.fill"
            }
        }
        
        var iconOutline: String {
            switch self {
                case .home: return "house"
                case .attendance: return "clock"
                case .projects: return "folder"
                case .requests: return "list.bullet.rectangle"
                case .messages: return "message"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    Group {
                        switch selectedTab {
                            case .home: HomeView()
                            case .attendance: AttendanceView()
                            case .projects: ProjectsListView()
                            case .requests: RequestsView()
                            case .messages: TeamMessagesView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    customTabBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(selectedTab.title)
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            ProfileView()
                        } label: {
                            ProfileMiniIcon(imageURL: auth.user?.imageURL, size: 32)
                        }
                        Button {
                            showLogoutAlert = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .confirmationDialog("Logout?", isPresented: $showLogoutAlert, titleVisibility: .visible) {
            Button("Yes, Logout", role: .destructive) {
                auth.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.icon : tab.iconOutline)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                        Text(tab.title)
                            .font(.caption2)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 0)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

struct ProfileMiniIcon: View {
    let imageURL: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
