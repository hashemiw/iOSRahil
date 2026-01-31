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

    enum Tab {
        case home, history, requests, profile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                
                VStack {
                    switch selectedTab {
                        case .home:
                            HomeView()
                        case .history:
                            HistoryView()
                        case .requests:
                            RequestsView()
                        case .profile:
                            ProfileView()
                    }
                }
            }
            .navigationTitle(selectedTab.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") {
                        showLogoutAlert = true
                    }
                    .foregroundColor(.primary)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: { selectedTab = .home }) {
                            Image(systemName: "house.fill")
                                .foregroundColor(selectedTab == .home ? .primary : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        Button(action: { selectedTab = .history }) {
                            Image(systemName: "clock")
                                .foregroundColor(selectedTab == .history ? .primary : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        Button(action: { selectedTab = .requests }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(selectedTab == .requests ? .primary : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        Button(action: { selectedTab = .profile }) {
                            Image(systemName: "person")
                                .foregroundColor(selectedTab == .profile ? .primary : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .frame(height: 49)
                    .background(Color(.clear))
                    .padding(.horizontal)
                }
            }
        }
        .confirmationDialog("Are you sure?", isPresented: $showLogoutAlert, titleVisibility: .visible) {
            Button("Yes, Logout", role: .destructive) {
                auth.logout()
            }
            Button("Cancel") {
            }
        } message: {
            Text("Do you really want to log out? You will need to enter your credentials again next time.")
        }
    }
}

extension MainTabView.Tab {
    var title: String {
        switch self {
        case .home: return "Home"
        case .history: return "History"
        case .requests: return "Requests"
        case .profile: return "Profile"
        }
    }
}
