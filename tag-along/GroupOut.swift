//
//  GroupOut.swift
//  tag-along
//
//  Created by Havish Komatreddy on 7/3/25.
//
import Foundation

struct GroupOut: Codable, Identifiable {
    var id: String { groupCode }

    let groupCode: String
    let groupName: String?
    let members: [String]
    let createdAt: Date
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case groupCode = "group_code"
        case groupName = "group_name"
        case members
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}
