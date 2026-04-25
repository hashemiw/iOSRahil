import Foundation

struct User: Identifiable, Codable {
    let id: UInt
    let email: String
    var name: String?
    var position: String?
    var team: String?
    var role:  String?
    var imageURL: String?
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
        case team = "team"
        case imageURL = "image_url"
        case createdAt = "created_at"
        case password = "password"
        case biometricEnabled = "biometric_enabled"
        case lastStatus = "last_status"
        case lastStatusAt = "last_status_at"
        case role = "role"
    }
}
