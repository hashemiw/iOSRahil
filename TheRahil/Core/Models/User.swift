import Foundation

struct User: Identifiable, Codable {
    let id: UInt
    let email: String
    var name: String?        // <--- var شود
    var position: String?    // <--- var شود
    var imageURL: String?    // <--- var شود (بسیار مهم)
    let createdAt: Date?
    let password: String?
    let biometricEnabled: Bool?
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
