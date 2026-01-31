//
//  AuthResponse.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/21.
//

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken) ?? ""
        
    }
}
