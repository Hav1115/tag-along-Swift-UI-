//
//  AuthService.swift
//  tag-along
//
//  Created by Havish Komatreddy on 6/24/25.
//

// AuthService.swift

import Foundation

/// Put this in your shared code folder (e.g. “Services”).
struct API {
    static let baseURL = URL(string: "http://192.168.86.246:8000")!
}

enum AuthError: LocalizedError {
    case server(message: String)
    case invalidResponse
    case decodingError
    var errorDescription: String? {
        switch self {
        case .server(let msg):    return msg
        case .invalidResponse:    return "Invalid server response"
        case .decodingError:      return "Failed to parse response"
        }
    }
}

// MARK: - Request / Response Models

struct EmailSignupRequest: Codable {
    let email: String
    let password: String
    let username: String
}

struct EmailLoginRequest: Codable {
    let email: String
    let password: String
}

struct AppleSignInRequest: Codable {
    let user_id: String
    let identity_token: String
    let authorization_code: String
    let email: String?
    let full_name: String?
}

struct GoogleSignInRequest: Codable {
    let user_id: String
    let id_token: String
    let email: String?
    let full_name: String?
}

struct AuthResponse: Codable {
    let message: String
    let user_id: String
}

class AuthService {
    
    private static func send<T: Codable, U: Codable>(
        path: String,
        method: String = "POST",
        body: T
    ) async throws -> U {
        let url = API.baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        if http.statusCode != 200 {
            // extract error message from body if possible
            if let serverMsg = String(data: data, encoding: .utf8) {
                throw AuthError.server(message: serverMsg)
            } else {
                throw AuthError.server(message: "Status code \(http.statusCode)")
            }
        }
        do {
            return try JSONDecoder().decode(U.self, from: data)
        } catch {
            throw AuthError.decodingError
        }
    }
    
    static func emailSignup(email: String, password: String, username: String) async throws -> String {
        let reqBody = EmailSignupRequest(email: email, password: password, username: username)
        let resp: AuthResponse = try await send(path: "/auth/email-signup", body: reqBody)
        return resp.user_id
    }
    
    static func emailLogin(email: String, password: String) async throws -> String {
        let reqBody = EmailLoginRequest(email: email, password: password)
        let resp: AuthResponse = try await send(path: "/auth/email-login", body: reqBody)
        return resp.user_id
    }
    
    static func signInWithApple(_ reqModel: AppleSignInRequest) async throws -> String {
        let resp: AuthResponse = try await send(path: "/auth/apple", body: reqModel)
        return resp.user_id
    }
    
    static func signInWithGoogle(_ reqModel: GoogleSignInRequest) async throws -> String {
        let resp: AuthResponse = try await send(path: "/auth/google", body: reqModel)
        return resp.user_id
    }
}
