//
//  HistoryView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/14.
//
import SwiftUI

struct HistoryView: View {
    
    @StateObject private var viewModel = HistoryViewModel()
    @EnvironmentObject var auth: AuthManager
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.historyItems.isEmpty {
                Text("No history found.")
                
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.historyItems) { item in
                    HStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(item.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: item.icon)
                                .foregroundColor(item.color)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(formatTime(item.time))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text(formatDate(item.time))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        
        .listStyle(.insetGrouped)
        .navigationTitle("History")
        .refreshable {
            await viewModel.fetchHistory(token: auth.token!)
        }
        .onAppear {
            Task {
                await viewModel.fetchHistory(token: auth.token!)
            }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
