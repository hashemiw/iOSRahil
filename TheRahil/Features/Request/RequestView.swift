//
//  RequestView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/14.
//

import SwiftUI

struct RequestsView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var requests: [Request] = []
    @State private var isPresentingModal = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    if isLoading && requests.isEmpty {
                        ProgressView("Loading Requests...")
                            .scaleEffect(1.5)
                            .padding(.top, 50)
                    } else if requests.isEmpty && !isLoading {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No requests found")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                            
                            Button("Try Again") {
                                Task { await fetchRequests() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(requests) { request in
                                RequestRowView(request: request)
                            }
                            .onDelete(perform: deleteRequest)
                        }
                        .listStyle(.insetGrouped)
                        .refreshable {
                            await fetchRequests()
                        }
                    }
                }
            }
            .navigationTitle("Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresentingModal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $isPresentingModal) {
                NewRequestSheet(isPresented: $isPresentingModal) { newRequest in
                    requests.insert(newRequest, at: 0)
                }
                .environmentObject(auth)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
            .onAppear {
                if requests.isEmpty {
                    Task { await fetchRequests() }
                }
            }
        }
    }
    
    func fetchRequests() async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            guard let token = auth.token else {
                throw NSError(domain: "Auth", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
            }
            
            requests = try await APIClient.shared.getRequests(token: token)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteRequest(at offsets: IndexSet) {
        requests.remove(atOffsets: offsets)
    }
}

struct RequestRowView: View {
    let request: Request
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconForType(request.type))
                    .foregroundColor(statusColor)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.type)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(request.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(request.status)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
                
                Text(formatDate(request.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    var statusColor: Color {
        switch request.status {
        case "APPROVED": return .green
        case "REJECTED": return .red
        default: return .orange
        }
    }
    
    func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "leave": return "airplane"
        case "overtime": return "clock"
        case "holiday": return "beach.umbrella"
        default: return "doc.text"
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}


import SwiftUI

struct NewRequestSheet: View {
    @Binding var isPresented: Bool
    let onRequestAdded: (Request) -> Void
    @EnvironmentObject var auth: AuthManager
    
    @State private var selectedType = "Leave"
    @State private var reason = ""
    @State private var selectedDate = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    let types = ["Leave", "Overtime", "Holiday Work", "Promotion"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Request Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Select Date",
                             selection: $selectedDate,
                             in: Date()...,
                             displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                
                Section(header: Text("Reason")) {
                    TextField("Enter reason...", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submitRequest) {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Submit")
                        }
                    }
                    .disabled(reason.isEmpty || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    func submitRequest() {
        Task {
            isSubmitting = true
            errorMessage = nil
            
            do {
                guard let token = auth.token else {
                    throw NSError(domain: "Auth", code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
                }
                
                let newReq = try await APIClient.shared.createRequest(
                    token: token,
                    type: selectedType,
                    reason: reason,
                    date: selectedDate
                )
                
                
                await MainActor.run {
                    onRequestAdded(newReq)
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
