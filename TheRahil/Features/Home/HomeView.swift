import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var lastStatus: String = "No Status"
    @State private var lastStatusTime: String = "--:--"
    
    let morningGreetings = ["Good Morning", "Rise and Shine", "Ready to conquer?"]
    let afternoonGreetings = ["Good Afternoon", "Keep pushing forward", "Great to see you"]
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(greetingText)
                            .font(.title.bold())
                            .foregroundColor(.primary)
                        
                        if let name = auth.user?.name {
                            Text(name.split(separator: " ").first.map(String.init) ?? name)
                                .font(.largeTitle.bold())
                                .foregroundColor(.primary)
                        } else {
                            Text("Dear User")
                                .font(.largeTitle.bold())
                                .foregroundColor(.primary)
                        }
                        
                        Text(getRandomQuote())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Last Status")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text(lastStatus)
                                    .font(.title2.bold())
                                    .foregroundColor(lastStatus == "IN" ? .green : (lastStatus == "OUT" ? .red : .gray))
                                Text(lastStatusTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    NavigationLink {
                        AttendanceView()
                    } label: {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.title2)
                            Text("Mark Attendance")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadLastStatus()
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return morningGreetings.randomElement() ?? "Good Morning"
        } else {
            return afternoonGreetings.randomElement() ?? "Good Afternoon"
        }
    }
    
    private func getRandomQuote() -> String {
        let quotes = [
            "Make today amazing.",
            "Your potential is endless.",
            "Focus on the good.",
            "Dream big, work hard."
        ]
        return quotes.randomElement() ?? "Have a nice day"
    }
    
    private func loadLastStatus() {
        if let status = auth.user?.lastStatus {
            lastStatus = status == "IN" ? "Checked In" : (status == "OUT" ? "Checked Out" : status)
        }
        
        if let date = auth.user?.lastStatusAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm - MMM d"
            lastStatusTime = formatter.string(from: date)
        }
    }
}
