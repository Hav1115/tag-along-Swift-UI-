//
//  SignupNav.swift
//  tag-along
//
//  Created by Havish Komatreddy on 6/26/25.
//

// SignupNav.swift
import Foundation

/// The two screens in our signup flow
enum SignupNav: Hashable {
    case userPrompt(email: String)
    case home
}
