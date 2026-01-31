import SwiftUI

struct AttendanceView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject var vm = AttendanceViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10)
                    
                    Text("Mark Attendance")
                        .font(.title.bold())
                    
                    VStack(spacing: 5) {
                        Text(statusText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                        
                        if let time = vm.lastStatusTime {
                            Text(timeString(from: time))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No recent activity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await vm.check(type: "IN", token: auth.token!, authManager: auth)
                        }
                    }) {
                        HStack {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Check In")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(vm.isLoading)
                    
                    Button(action: {
                        Task {
                            await vm.check(type: "OUT", token: auth.token!, authManager: auth)
                        }
                    }) {
                        HStack {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.left.circle.fill")
                                Text("Check Out")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(vm.isLoading)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert(isPresented: $vm.showAlert) {
            Alert(
                title: Text(vm.alertTitle),
                message: Text(vm.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadInitialStatus()
        }
    }
    
    
    private func loadInitialStatus() {
        if let lastStatus = auth.user?.lastStatus {
            vm.currentStatus = lastStatus
            vm.lastStatusTime = auth.user?.lastStatusAt
        }
    }
    
    private var statusText: String {
        switch vm.currentStatus {
        case "IN":
            return "Currently Checked In"
        case "OUT":
            return "Currently Checked Out"
        default:
            return "Select a button to mark your attendance."
        }
    }
    
    private var statusColor: Color {
        switch vm.currentStatus {
        case "IN":
            return .green
        case "OUT":
            return .red
        default:
            return .secondary
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
