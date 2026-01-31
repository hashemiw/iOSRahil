import Foundation

struct User: Identifiable, Codable {
    let id: UInt
    let email: String
    let name: String?
    let position: String?
    let imageURL: String?
    let createdAt: Date?
    let password: String?
    let biometricEnabled: Bool?
    
    // فیلدهای جدید
    let lastStatus: String?
    let lastStatusAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case email = "email"
        case name = "name"
        case position = "position"
        case imageURL = "image_url"
        case createdAt = "created_at"
        case password = "password"
        case biometricEnabled = "biometric_enabled"
        case lastStatus = "last_status"
        case lastStatusAt = "last_status_at"
    }
}
