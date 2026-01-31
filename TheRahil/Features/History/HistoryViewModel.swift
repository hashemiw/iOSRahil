//
//  HistoryViewModel.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/20.
//

import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    func fetchHistory(token: String) async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            historyItems = try await APIClient.shared.getHistory(token: token)
            
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
            showError = true
        }
    }
}

