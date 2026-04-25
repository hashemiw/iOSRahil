//
//  ProjectOverviewView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//

import SwiftUI


struct ProjectOverviewView: View {
    let project: Project
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(project.name)
                                .font(.title2.bold())
                            
                            if !project.team.isEmpty {
                                Text(project.team)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("Created", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDate(project.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                HStack(spacing: 12) {
                    StatCard(title: "Total", value: "0", icon: "folder", color: .blue)
                    StatCard(title: "To Do", value: "0", icon: "circle", color: .orange)
                    StatCard(title: "In Progress", value: "0", icon: "arrow.right.circle", color: .blue)
                    StatCard(title: "Done", value: "0", icon: "checkmark.circle", color: .green)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Team Members")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.secondary)
                        Text("View team members in task details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
