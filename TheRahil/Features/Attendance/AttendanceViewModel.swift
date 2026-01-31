import Foundation
import CoreLocation
import Combine

@MainActor
final class AttendanceViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    @Published var currentStatus: String = "UNKNOWN"
    @Published var lastStatusTime: Date?

    func check(type: String, token: String, authManager: AuthManager) async {
        guard let deviceID = DeviceManager.shared.deviceID else {
            self.alertTitle = "Error"
            self.alertMessage = "Device not registered"
            self.showAlert = true
            return
        }
        
        isLoading = true
        do {
            try await APIClient.shared.request(
                path: "/api/attendance",
                method: "POST",
                token: token,
                body: [
                    "Type": type,
                    "DeviceID": deviceID,
                    "Lat": 35.6892,
                    "Lng": 51.3890
                ]
            )
            
            self.currentStatus = type
            self.lastStatusTime = Date()
            
            self.alertTitle = "Success"
            self.alertMessage = type == "IN" ? "Check-in successful." : "Check-out successful."
            self.showAlert = true
            
            await authManager.fetchProfile(token: token)
            
        } catch {
            self.alertTitle = "Error"
            self.alertMessage = "Operation failed. Please try again."
            self.showAlert = true
        }
        isLoading = false
    }
}
