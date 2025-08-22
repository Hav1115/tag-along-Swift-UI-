import Foundation

struct GroupResponse: Codable {
    let success: Bool
    let group_code: String
    let group_name: String?
    let members: [String]
    let created_at: String
    let expires_at: String?
    let message: String?
    
    var expiresAtDate: Date? {
        guard let expires_at = expires_at else { return nil }
        return ISO8601DateFormatter().date(from: expires_at)
    }
}

struct SimpleResponse: Codable {
    let success: Bool
    let message: String?
}

struct CreateGroupRequest: Codable {
    let group_name: String
    let expiration_minutes: Int
    let creator_username: String
}

struct GroupDetails {
    let name: String
    let code: String
    let members: [String]
    let expiresAt: Date
    var timeRemaining: Int = 0
    
    static func from(_ response: GroupResponse) -> GroupDetails? {
        guard let expiresAt = response.expiresAtDate else { return nil }
        
        return GroupDetails(
            name: response.group_name ?? "Unnamed Group",
            code: response.group_code,
            members: response.members,
            expiresAt: expiresAt,
            timeRemaining: Int(expiresAt.timeIntervalSinceNow)
        )
    }
}
