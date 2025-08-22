import SwiftUI

/// All the screens in your flow:
enum Route: Hashable {
    case signupemail
    case userPrompt(email: String)
    case home
    case googleSignup
    case duckwalk
    case appleSignup
    case login
    case signupHome
    case emailLogin
    case creategroup
    case joingroup
    case viewGroup
    case groupDetail(groupCode: String)
    case land
    case tabs(start: Int  = 0)
}

final class Router: ObservableObject {
    @Published var route: Route = .land
}
