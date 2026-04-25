import Foundation
import SwiftUI

final class APIClient {
    static let shared = APIClient()
    private init() {}
    
        
    private let baseURL = URL(string: "http://localhost:8080")!
//    private let baseURL = URL(string: "http://172.20.10.2:8080")!
    
    func request(
        path: String,
        method: String,
        token: String? = nil,
        body: [String: Any]? = nil
    ) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
                
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
                
        if !(200...299).contains(httpResponse.statusCode) {
            let responseString = String(data: data, encoding: .utf8) ?? ""
            
            if httpResponse.statusCode == 401 {
                throw URLError(.userAuthenticationRequired)
            }
            
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorDict["error"] as? String {
                throw NSError(domain: "APIError", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw URLError(.badServerResponse)
        }
        
        return data
    }
    
    func updateProfile(
        name: String?,
        position: String?,
        team: String?,
        email: String?,
        password: String?,
        token: String
    ) async throws -> Data {
        var body: [String: Any] = [:]
        if let name = name, !name.isEmpty { body["name"] = name }
        if let position = position, !position.isEmpty { body["position"] = position }
        if let team = team, !team.isEmpty { body["team"] = team }
        if let email = email, !email.isEmpty { body["email"] = email }
        if let password = password, !password.isEmpty { body["password"] = password }

        return try await request(
            path: "/api/profile",
            method: "PATCH",
            token: token,
            body: body
        )
    }
    
    func uploadProfileImage(imageData: Data, token: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/api/profile/image")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
                
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let responseString = String(data: data, encoding: .utf8) ?? ""
            throw URLError(.badServerResponse)
        }

        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            if let imageUrl = json["image_url"] as? String {
                return imageUrl
            } else if let imageUrl = json["imageUrl"] as? String {
                return imageUrl
            } else if let message = json["message"] as? String {
                if message.contains("http://") {
                    return message
                }
            }
        }
        
        throw URLError(.cannotParseResponse)
    }
    
    func getRequests(token: String) async throws -> [Request] {
        let data = try await request(path: "/api/requests", method: "GET", token: token)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let requests = try decoder.decode([Request].self, from: data)
            return requests
        } catch {
            throw error
        }
    }

    
    func createRequest(token: String, type: String, reason: String, date: Date) async throws -> Request {
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        
        let body: [String: Any] = [
            "type": type,
            "reason": reason,
            "date": dateString
        ]
        
        
        do {
            let data = try await request(
                path: "/api/requests",
                method: "POST",
                token: token,
                body: body
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let request = try decoder.decode(Request.self, from: data)
            return request
        } catch let error as URLError where error.code == .userAuthenticationRequired {
            try await AuthManager.shared.refreshTokens()
            
            if let newToken = AuthManager.shared.token {
                return try await createRequest(token: newToken, type: type, reason: reason, date: date)
            } else {
                throw error
            }
        } catch {
            throw error
        }
    }
    

    func getMessages(token: String) async throws -> [Message] {
        let data = try await request(path: "/api/messages", method: "GET", token: token)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let messages = try decoder.decode([Message].self, from: data)
        return messages
    }

    func sendMessage(token: String, content: String) async throws -> Message {
        let body: [String: Any] = ["content": content]
        
        let data = try await request(
            path: "/api/messages",
            method: "POST",
            token: token,
            body: body
        )
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let message = try decoder.decode(Message.self, from: data)
        return message
    }

    func getTeams(token: String) async throws -> [String] {
        let data = try await request(path: "/api/teams", method: "GET", token: token)
        
        if let teams = try? JSONDecoder().decode([String].self, from: data) {
            return teams
        }
        return []
    }


    func getMessagesByTeam(token: String, team: String) async throws -> [Message] {
        let encodedTeam = team.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? team
        let data = try await request(path: "/api/admin/messages/\(encodedTeam)", method: "GET", token: token)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let messages = try decoder.decode([Message].self, from: data)
        return messages
    }
    
    func getHistory(token: String) async throws -> [HistoryItem] {
        let data = try await request(path: "/api/history", method: "GET", token: token)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try decoder.decode(HistoryResponse.self, from: data)
            
            var items: [HistoryItem] = []
            
            for log in response.logs {
                let title = log.type == "IN" ? "Checked In" : "Checked Out"
                let icon = log.type == "IN" ? "arrow.right.circle.fill" : "arrow.left.circle.fill"
                let color: Color = log.type == "IN" ? .green : .red
                
                items.append(HistoryItem(
                    title: title,
                    subtitle: "Device ID: \(log.deviceID)",
                    time: log.createdAt,
                    type: "log",
                    icon: icon,
                    color: color
                ))
            }
            
            for req in response.requests {
                items.append(HistoryItem(
                    title: req.type,
                    subtitle: req.reason,
                    time: req.createdAt,
                    type: "request",
                    icon: "doc.text.fill",
                    color: .orange
                ))
            }
            
            items.sort { $0.time < $1.time }
            return items
        } catch {
            throw error
        }
    }
}



extension APIClient {
    
    
    func getProjects(token: String, team: String? = nil) async throws -> [Project] {
        var path = "/api/projects"
        if let team = team, !team.isEmpty {
            path += "?team=\(team.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? team)"
        }
        
        let data = try await request(path: path, method: "GET", token: token)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Project].self, from: data)
    }
    
    func getProject(token: String, projectId: UInt) async throws -> Project {
        let data = try await request(path: "/api/projects/\(projectId)", method: "GET", token: token)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Project.self, from: data)
    }
    
    func createProject(token: String, name: String, description: String, team: String) async throws -> Project {
        let body: [String: Any] = [
            "name": name,
            "description": description,
            "team": team
        ]
        let data = try await request(path: "/api/projects", method: "POST", token: token, body: body)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Project.self, from: data)
    }
    
    func updateProject(token: String, projectId: UInt, name: String?, description: String?, team: String?) async throws -> Data {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let description = description { body["description"] = description }
        if let team = team { body["team"] = team }
        
        return try await request(path: "/api/projects/\(projectId)", method: "PUT", token: token, body: body)
    }
    
    func deleteProject(token: String, projectId: UInt) async throws -> Data {
        return try await request(path: "/api/projects/\(projectId)", method: "DELETE", token: token)
    }
    
    
    func getTasks(token: String, projectId: UInt) async throws -> [Tasks] {
        let data = try await request(path: "/api/projects/\(projectId)/tasks", method: "GET", token: token)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Tasks].self, from: data)
    }
    
    func getTask(token: String, projectId: UInt, taskId: UInt) async throws -> Tasks {
        let data = try await request(path: "/api/projects/\(projectId)/tasks/\(taskId)", method: "GET", token: token)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Tasks.self, from: data)
    }
    
    func createTask(token: String, projectId: UInt, title: String, description: String, status: String, priority: String, assignedTo: UInt?, dueDate: Date?) async throws -> Tasks {
        var body: [String: Any] = [
            "title": title,
            "description": description,
            "status": status,
            "priority": priority
        ]
        
        if let assignedTo = assignedTo {
            body["assigned_to"] = assignedTo
        }
        
        if let dueDate = dueDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            body["due_date"] = formatter.string(from: dueDate)
        }
        
        let data = try await request(path: "/api/projects/\(projectId)/tasks", method: "POST", token: token, body: body)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Tasks.self, from: data)
    }
    
    func updateTask(token: String, projectId: UInt, taskId: UInt, title: String?, description: String?, status: String?, priority: String?, assignedTo: UInt?, dueDate: Date?) async throws -> Tasks {
        var body: [String: Any] = [:]
        if let title = title { body["title"] = title }
        if let description = description { body["description"] = description }
        if let status = status { body["status"] = status }
        if let priority = priority { body["priority"] = priority }
        if let assignedTo = assignedTo { body["assigned_to"] = assignedTo }
        if let dueDate = dueDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            body["due_date"] = formatter.string(from: dueDate)
        }
        
        let data = try await request(path: "/api/projects/\(projectId)/tasks/\(taskId)", method: "PUT", token: token, body: body)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Tasks.self, from: data)
    }
    
    func deleteTask(token: String, projectId: UInt, taskId: UInt) async throws -> Data {
        return try await request(path: "/api/projects/\(projectId)/tasks/\(taskId)", method: "DELETE", token: token)
    }
    
    
    func getProjectMembers(token: String, projectId: UInt) async throws -> [TaskUser] {
        let data = try await request(path: "/api/projects/\(projectId)/members", method: "GET", token: token)
        let decoder = JSONDecoder()
        return try decoder.decode([TaskUser].self, from: data)
    }
    
    
    func getMyTasks(token: String) async throws -> [MyTask] {
        print("🔵 [API] getMyTasks called")
        
        let data = try await request(path: "/api/my-tasks", method: "GET", token: token)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🟢 [API] Raw Response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let tasks = try decoder.decode([MyTask].self, from: data)
            print("🟢 [API] Decoded \(tasks.count) tasks")
            return tasks
        } catch {
            print("🔴 [API] Decode Error: \(error)")
            print("🔴 [API] Error localized: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getTeamsWithMessages(token: String) async throws -> [TeamData] {
        let data = try await request(path: "/api/teams/messages", method: "GET", token: token)
        return try JSONDecoder().decode([TeamData].self, from: data)
    }

    func sendMessage(token: String, content: String, team: String) async throws -> Message {
        let body: [String: Any] = ["content": content, "team": team]
        let data = try await request(path: "/api/messages", method: "POST", token: token, body: body)
        return try JSONDecoder().decode(Message.self, from: data)
    }

    func getTeamMembers(token: String, team: String) async throws -> [User] {
        let data = try await request(path: "/api/teams/\(team)/members", method: "GET", token: token)
        return try JSONDecoder().decode([User].self, from: data)
    }

    func createTeam(token: String, name: String) async throws {
        let body: [String: Any] = ["name": name]
        _ = try await request(path: "/api/teams", method: "POST", token: token, body: body)
    }

    struct TeamData: Codable {
        let id: String
        let name: String
        let memberCount: Int
        let unreadCount: Int
        let lastMessage: String?
        let lastMessageTime: Date?
    }
    
}

struct HistoryResponse: Codable {
    let logs: [AttendanceLog]
    let requests: [Request]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        logs = try container.decodeIfPresent([AttendanceLog].self, forKey: .logs) ?? []
        requests = try container.decodeIfPresent([Request].self, forKey: .requests) ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case logs, requests
    }
}

struct AttendanceLog: Codable {
    let id: UInt
    let userID: UInt
    let deviceID: UInt
    let type: String
    let lat: Double
    let lng: Double
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case deviceID = "device_id"
        case type
        case lat, lng
        case createdAt = "created_at"
    }
}


extension APIClient {

    func sendFileMessage(
        token: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        content: String,
        team: String? = nil,
        replyToID: UInt? = nil
    ) async throws -> Message {
        let url = baseURL.appendingPathComponent("/api/messages/file")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        if !content.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(content)\r\n".data(using: .utf8)!)
        }

        if let team = team, !team.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"team\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(team)\r\n".data(using: .utf8)!)
        }

        if let replyToID = replyToID {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"reply_to_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(replyToID)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Message.self, from: data)
    }

    func updateMessage(token: String, messageID: UInt, content: String) async throws -> Message {
        let body: [String: Any] = ["content": content]
        let data = try await request(
            path: "/api/messages/\(messageID)",
            method: "PUT",
            token: token,
            body: body
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Message.self, from: data)
    }

    func deleteMessage(token: String, messageID: UInt) async throws {
        _ = try await request(
            path: "/api/messages/\(messageID)",
            method: "DELETE",
            token: token
        )
    }

    func addReaction(token: String, messageID: UInt, emoji: String) async throws -> MessageReaction {
        let body: [String: Any] = ["emoji": emoji]
        let data = try await request(
            path: "/api/messages/\(messageID)/reactions",
            method: "POST",
            token: token,
            body: body
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MessageReaction.self, from: data)
    }

    func removeReaction(token: String, messageID: UInt, emoji: String) async throws {
        let body: [String: Any] = ["emoji": emoji]
        _ = try await request(
            path: "/api/messages/\(messageID)/reactions",
            method: "DELETE",
            token: token,
            body: body
        )
    }

    func getReactions(token: String, messageID: UInt) async throws -> [MessageReaction] {
        let data = try await request(
            path: "/api/messages/\(messageID)/reactions",
            method: "GET",
            token: token
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MessageReaction].self, from: data)
    }

    func sendMessage(token: String, content: String, team: String? = nil, replyToID: UInt? = nil) async throws -> Message {
        var body: [String: Any] = ["content": content]
        if let team = team { body["team"] = team }
        if let replyToID = replyToID { body["reply_to_id"] = replyToID }

        let data = try await request(
            path: "/api/messages",
            method: "POST",
            token: token,
            body: body
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Message.self, from: data)
    }
}
