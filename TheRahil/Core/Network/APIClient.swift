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
        email: String?,
        password: String?,
        token: String
    ) async throws -> Data {
        var body: [String: Any] = [:]
        if let name = name, !name.isEmpty { body["name"] = name }
        if let position = position, !position.isEmpty { body["position"] = position }
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
            
            items.sort { $0.time > $1.time }
            return items
        } catch {
            throw error
        }
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

