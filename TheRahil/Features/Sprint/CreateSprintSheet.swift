//
//  CreateSprintSheet.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/13.
//


import SwiftUI

struct CreateSprintSheet: View {
    @Binding var isPresented: Bool
    let projectId: UInt
    let onSprintCreated: (Sprint) -> Void
    @EnvironmentObject var auth: AuthManager
    
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(14 * 24 * 60 * 60)
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Sprint Details")) {
                    TextField("Sprint Name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                
                Section(header: Text("Duration")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker(
                        "End Date",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                }
                
                Section {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("\(daysBetween(startDate, endDate)) days")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        createSprint()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(name.isEmpty || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
    
    private func createSprint() {
        isPresented = false
    }
}
