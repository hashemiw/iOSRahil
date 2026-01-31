
import Foundation

struct Device: Identifiable, Codable {
    let id: UInt
    let uuid: String
    let platform: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case uuid = "UUID"
        case platform = "Platform"
        case createdAt = "created_at"
    }
}


struct DeviceRegisterResponse: Codable {
    let deviceID: UInt

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
    }
}
